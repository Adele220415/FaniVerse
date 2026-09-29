import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

import '../core/constants/cloudinary_config.dart';
import '../core/result.dart';

/// What kind of file is being uploaded. Maps onto Cloudinary's `resource_type`
/// plus a client-side size ceiling, because different resources have very
/// different costs.
enum MediaKind {
  image('image', 10 * 1024 * 1024),
  video('video', 100 * 1024 * 1024),
  audio('video', 20 * 1024 * 1024);

  const MediaKind(this.resourceType, this.maxBytes);

  /// Cloudinary `resource_type`. Audio uses `video` because Cloudinary has no
  /// separate audio resource type - an mp3 is delivered by the video pipeline.
  final String resourceType;

  /// Uploads above this size are rejected before any bytes leave the device.
  final int maxBytes;

  String get label => switch (this) {
        MediaKind.image => 'Image',
        MediaKind.video => 'Video',
        MediaKind.audio => 'Audio',
      };
}

/// The parts of Cloudinary's upload response this app actually uses.
class CloudinaryUpload {
  const CloudinaryUpload({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.format,
    this.width,
    this.height,
    this.bytes,
  });

  /// The HTTPS delivery URL. This is the value persisted to Firestore.
  final String url;

  /// Cloudinary's identifier, needed later to delete or transform the asset.
  final String publicId;

  final String resourceType;
  final String format;
  final int? width;
  final int? height;
  final int? bytes;
}

/// Uploads local files to Cloudinary using an **unsigned** upload preset.
///
/// Takes an [XFile] rather than a path so the same code works on Android, iOS,
/// Windows, macOS, Linux and the web. On native platforms an `XFile` wraps a
/// file on disk; on the web the pickers hand back an in-memory blob with no
/// path at all, so reading bytes through `XFile` is the only portable route.
/// (`dart:io` is deliberately not imported - it does not exist on the web.)
///
/// No API secret is involved, so this is safe to ship in a client build. If
/// this service is used when [CloudinaryConfig.isConfigured] is false, every
/// upload returns a configuration error instead of throwing.
class CloudinaryService {
  final http.Client _client;

  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  /// Upload [file] to Cloudinary.
  ///
  /// [folder] is the Cloudinary folder to place the asset in (for example
  /// `faniverse/content`). [tags] are optional asset tags.
  ///
  /// Returns a [CloudinaryUpload] on success, or an error result describing
  /// what went wrong. Never throws.
  Future<Result<CloudinaryUpload>> uploadFile({
    required XFile file,
    required MediaKind kind,
    String? folder,
    List<String> tags = const [],
  }) async {
    final configError = CloudinaryConfig.missingReason;
    if (configError != null) {
      return Result.error(configError);
    }

    // XFile.length() reads the size without pulling the whole file into memory,
    // so an oversized file is rejected before any upload starts.
    final int length;
    try {
      length = await file.length();
    } catch (e) {
      return Result.error('Could not read the selected file: $e');
    }

    if (length == 0) {
      return Result.error('The selected file is empty');
    }
    if (length > kind.maxBytes) {
      final limitMb = (kind.maxBytes / (1024 * 1024)).round();
      final sizeMb = (length / (1024 * 1024)).toStringAsFixed(1);
      return Result.error('${kind.label} is too large ($sizeMb MB). The limit is $limitMb MB.');
    }

    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      return Result.error('Could not read the selected file: $e');
    }

    final uri = Uri.parse(CloudinaryConfig.uploadEndpoint(kind.resourceType));
    final request = http.MultipartRequest('POST', uri)
      // The preset name is the only credential sent. Cloudinary scopes it to
      // upload-only and applies whatever restrictions the preset defines.
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      // The filename is what Cloudinary names the asset and infers its format
      // from, so it has to be a real name with a real extension. On the web
      // this is the only filename available at all.
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: _safeFilename(file, kind)));

    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }
    if (tags.isNotEmpty) {
      request.fields['tags'] = tags.join(',');
    }

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final body = _decodeBody(response.body);

      if (response.statusCode != 200) {
        return Result.error(_extractCloudinaryError(body, response.statusCode));
      }

      // Cloudinary always answers a successful upload with secure_url.
      final url = body['secure_url']?.toString();
      if (url == null || url.isEmpty) {
        return Result.error('Cloudinary accepted the upload but returned no URL');
      }

      return Result.success(
        CloudinaryUpload(
          url: url,
          publicId: body['public_id']?.toString() ?? '',
          resourceType: body['resource_type']?.toString() ?? kind.resourceType,
          format: body['format']?.toString() ?? '',
          width: (body['width'] as num?)?.toInt(),
          height: (body['height'] as num?)?.toInt(),
          bytes: (body['bytes'] as num?)?.toInt(),
        ),
      );
    } on http.ClientException catch (e) {
      // Thrown by both the native IO client and the web client on a dropped
      // connection, so this is the portable network-failure signal.
      return Result.error('Network error while uploading: ${e.message}');
    } catch (e) {
      return Result.error('Upload failed: $e');
    }
  }

  /// A filename guaranteed to be a bare basename with an extension.
  ///
  /// `XFile.name` is not dependable enough to pass straight through:
  ///
  ///  * On native it is derived from the file's path, and it is split only on
  ///    the *platform's* separator - so a path carrying the other separator
  ///    yields a partial path rather than a basename.
  ///  * `XFile.fromData` explicitly discards its `name` argument on native
  ///    platforms, so a file with no path reports an empty name.
  ///
  /// Sending a local path to Cloudinary would publish the device's directory
  /// layout in the asset name and in its delivered URL, so the path is always
  /// reduced to its final segment. Cloudinary also infers the stored format
  /// from the extension, so an unnamed or extension-less file is given a
  /// plausible one instead of being sent as-is.
  String _safeFilename(XFile file, MediaKind kind) {
    final segments = file.name
        .trim()
        .split(RegExp(r'[/\\]'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    final name = segments.isEmpty ? '' : segments.last;

    if (name.isNotEmpty && name.contains('.')) {
      return name;
    }

    final extension = switch (kind) {
      MediaKind.image => 'jpg',
      MediaKind.video => 'mp4',
      MediaKind.audio => 'mp3',
    };

    // Keep any recognisable stem so assets stay distinguishable in the
    // Cloudinary media library rather than all being called "upload".
    final stem = name.isEmpty ? 'upload' : name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '$stem.$extension';
  }

  /// Delete an asset by [publicId]. Requires a *signed* request, so this needs
  /// a server or Cloud Function holding the API secret and will fail against an
  /// unsigned-only setup. Left in place so the call sites are honest about it.
  Future<Result<void>> deleteAsset({
    required String publicId,
    required String resourceType,
  }) async {
    return Result.error(
      'Deleting from Cloudinary needs a signed request from a server holding the '
      'API secret. The Cloudinary URL can still be cleared in Firestore.',
    );
  }

  /// Cloudinary returns a JSON body even for 4xx, but guard against
  /// non-JSON (proxy errors, HTML error pages) so callers never crash.
  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Cloudinary error bodies look like
  /// `{"error": {"message": "..."}}`. Fall back to a generic status message.
  String _extractCloudinaryError(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    if (error is String && error.isNotEmpty) {
      return error;
    }
    return 'Upload failed with status $statusCode';
  }
}
