import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:faniverse_main/core/constants/cloudinary_config.dart';
import 'package:faniverse_main/services/cloudinary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Exercises the Cloudinary upload path without touching the network.
///
/// `MockClient.streaming` is used rather than plain `MockClient` because the
/// latter rebuilds a bare `Request` and discards the multipart fields - and
/// those fields (`upload_preset`, `folder`, `filename`) are exactly what needs
/// verifying.
///
/// Every fixture is an in-memory [XFile] rather than a real file on disk. That
/// mirrors what the web build actually receives (a blob with no path), so the
/// tests exercise the same code path the browser hits.
///
/// The success-path tests depend on `CloudinaryConfig.isConfigured`, which is
/// decided at compile time by dart-defines. Run them with:
///
/// ```
/// flutter test --dart-define=CLOUDINARY_CLOUD_NAME=test_cloud \
///              --dart-define=CLOUDINARY_PRESET=test_preset
/// ```
///
/// Without those flags they skip rather than fail, so a plain `flutter test`
/// still passes where no Cloudinary account exists.
void main() {
  final configured = CloudinaryConfig.isConfigured;

  /// Skips the current test unless the build supplied the Cloudinary defines.
  void requireConfig() {
    if (!configured) {
      markTestSkipped('needs CLOUDINARY_CLOUD_NAME and CLOUDINARY_PRESET defines');
    }
  }

  http.StreamedResponse jsonResponse(Object body, int status) => http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(body))),
        status,
        headers: {'content-type': 'application/json'},
      );

  late Directory _tempDir;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('cloudinary_test');
  });

  tearDownAll(() async {
    if (_tempDir.existsSync()) _tempDir.deleteSync(recursive: true);
  });

  /// A file with no name and no path - the worst case the service must survive.
  XFile namelessFile(int bytes) => XFile.fromData(Uint8List(bytes));

  /// A file with a real name, as a native picker would return.
  XFile namedFile(int bytes, String name) {
    final file = File('${_tempDir.path}/$name')..writeAsBytesSync(List.filled(bytes, 0x41));
    return XFile(file.path);
  }

  XFile tinyPng() => namedFile(4, 'pixel.png');

  group('CloudinaryConfig', () {
    test('is configured only when both defines are present', () {
      expect(CloudinaryConfig.isConfigured, configured);
      if (configured) {
        expect(CloudinaryConfig.missingReason, isNull);
      } else {
        expect(CloudinaryConfig.missingReason, contains('dart-define'));
      }
    });
  });

  group('CloudinaryService validation', () {
    test('short-circuits on configuration before reading the file', () async {
      // The config guard runs first on purpose: when Cloudinary is missing,
      // "not configured" is far more actionable than any file complaint.
      if (configured) {
        markTestSkipped('only meaningful in an unconfigured build');
        return;
      }

      final result = await CloudinaryService().uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, CloudinaryConfig.missingReason);
    });

    test('rejects an empty file', () async {
      requireConfig();
      if (!configured) return;

      final result = await CloudinaryService().uploadFile(
        file: namelessFile(0),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('empty'));
    });

    test('rejects a file over the per-kind size limit', () async {
      requireConfig();
      if (!configured) return;

      // One byte over the 10 MB image ceiling.
      final result = await CloudinaryService().uploadFile(
        file: namelessFile(10 * 1024 * 1024 + 1),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('too large'));
    });

    test('applies a tighter ceiling to audio than to video', () async {
      // Guards against the two ceilings drifting to the same value.
      expect(MediaKind.audio.maxBytes, lessThan(MediaKind.video.maxBytes));
      expect(MediaKind.image.maxBytes, lessThan(MediaKind.video.maxBytes));
    });
  });

  group('CloudinaryService upload', () {
    test('returns the secure_url on a successful upload', () async {
      requireConfig();
      if (!configured) return;

      final client = MockClient.streaming((request, _) async {
        return jsonResponse({
          'secure_url': 'https://res.cloudinary.com/test_cloud/image/upload/v1/pixel.png',
          'public_id': 'v1/pixel',
          'resource_type': 'image',
          'format': 'png',
          'width': 1,
          'height': 1,
          'bytes': 4,
        }, 200);
      });

      final result = await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final upload = result.data!;
      expect(upload.url, 'https://res.cloudinary.com/test_cloud/image/upload/v1/pixel.png');
      expect(upload.publicId, 'v1/pixel');
      expect(upload.format, 'png');
      expect(upload.width, 1);
      expect(upload.bytes, 4);
    });

    test('posts to the image endpoint with the preset, folder and filename', () async {
      requireConfig();
      if (!configured) return;

      Uri? seenUri;
      Map<String, String>? seenFields;
      String? seenFilename;

      final client = MockClient.streaming((request, _) async {
        seenUri = request.url;
        if (request is http.MultipartRequest) {
          seenFields = request.fields;
          // The filename is what Cloudinary names the asset. On the web it is
          // the only filename available, so it must always be sent.
          seenFilename = request.files.single.filename;
        }
        return jsonResponse({'secure_url': 'https://example.test/x.png'}, 200);
      });

      await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
        folder: 'faniverse/content/images',
      );

      expect(seenUri.toString(), contains('api.cloudinary.com/v1_1/'));
      expect(seenUri.toString(), endsWith('/image/upload'));
      expect(seenFields!['upload_preset'], CloudinaryConfig.uploadPreset);
      expect(seenFields!['folder'], 'faniverse/content/images');
      expect(seenFilename, 'pixel.png');
    });

    test('never leaks a local directory path into the filename', () async {
      requireConfig();
      if (!configured) return;

      // Regression guard: XFile.name is path-derived on native and is split
      // only on the platform separator, so it can hand back a partial path.
      // Whatever it returns, Cloudinary must only ever see the final segment -
      // otherwise the device's folder layout ends up in the asset name and in
      // every delivered URL.
      final deep = File('${_tempDir.path}/profile/photos/holiday.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(4, 0x41));

      String? seenFilename;
      final client = MockClient.streaming((request, _) async {
        if (request is http.MultipartRequest) seenFilename = request.files.single.filename;
        return jsonResponse({'secure_url': 'https://example.test/x.png'}, 200);
      });

      await CloudinaryService(client: client).uploadFile(
        file: XFile(deep.path),
        kind: MediaKind.image,
      );

      expect(seenFilename, 'holiday.png');
      expect(seenFilename, isNot(contains('/')));
      expect(seenFilename, isNot(contains(r'\')));
    });

    test('synthesises a filename when the file has no name', () async {
      requireConfig();
      if (!configured) return;

      // XFile.fromData discards its `name` argument on native platforms, so a
      // file with no path reports an empty name. Cloudinary needs a real name
      // with an extension, so the service has to supply one.
      String? seenFilename;
      final client = MockClient.streaming((request, _) async {
        if (request is http.MultipartRequest) seenFilename = request.files.single.filename;
        return jsonResponse({'secure_url': 'https://example.test/x.png'}, 200);
      });

      final result = await CloudinaryService(client: client).uploadFile(
        file: namelessFile(4),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(seenFilename, isNotNull);
      expect(seenFilename, isNotEmpty);
      expect(seenFilename, endsWith('.jpg'));
    });

    test('falls back per media kind when synthesising an extension', () async {
      requireConfig();
      if (!configured) return;

      final seen = <String>[];
      final client = MockClient.streaming((request, _) async {
        if (request is http.MultipartRequest) seen.add(request.files.single.filename!);
        return jsonResponse({'secure_url': 'https://example.test/x'}, 200);
      });
      final service = CloudinaryService(client: client);

      await service.uploadFile(file: namelessFile(4), kind: MediaKind.image);
      await service.uploadFile(file: namelessFile(4), kind: MediaKind.video);
      await service.uploadFile(file: namelessFile(4), kind: MediaKind.audio);

      expect(seen, ['upload.jpg', 'upload.mp4', 'upload.mp3']);
    });

    test('sends tags when supplied', () async {
      requireConfig();
      if (!configured) return;

      Map<String, String>? seenFields;
      final client = MockClient.streaming((request, _) async {
        if (request is http.MultipartRequest) seenFields = request.fields;
        return jsonResponse({'secure_url': 'https://example.test/x.png'}, 200);
      });

      await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
        tags: const ['avatars', 'faniverse'],
      );

      expect(seenFields!['tags'], 'avatars,faniverse');
    });

    test('routes video and audio to the video endpoint', () async {
      requireConfig();
      if (!configured) return;

      final seen = <String>[];
      final client = MockClient.streaming((request, _) async {
        seen.add(request.url.path);
        return jsonResponse({'secure_url': 'https://example.test/x'}, 200);
      });
      final service = CloudinaryService(client: client);

      final clip = namedFile(4, 'clip.mp4');
      await service.uploadFile(file: clip, kind: MediaKind.video);
      await service.uploadFile(file: clip, kind: MediaKind.audio);

      // Cloudinary has no separate audio resource type, so an mp3 is delivered
      // by the video pipeline. Both must land on /video/upload.
      expect(seen, hasLength(2));
      expect(seen, everyElement(endsWith('/video/upload')));
    });

    test('surfaces the message from a Cloudinary error body', () async {
      requireConfig();
      if (!configured) return;

      final client = MockClient.streaming(
        (request, _) async => jsonResponse({
          'error': {'message': 'Invalid preset name'},
        }, 400),
      );

      final result = await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid preset name');
    });

    test('falls back to a status message when the body is not JSON', () async {
      requireConfig();
      if (!configured) return;

      final client = MockClient.streaming((request, _) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('<html>502 Bad Gateway</html>')),
          502,
        );
      });

      final result = await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('502'));
    });

    test('errors when a 200 response carries no secure_url', () async {
      requireConfig();
      if (!configured) return;

      final client = MockClient.streaming(
        (request, _) async => jsonResponse({'public_id': 'orphan'}, 200),
      );

      final result = await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('no URL'));
    });

    test('returns an error, not a crash, when the network fails', () async {
      requireConfig();
      if (!configured) return;

      final client = MockClient.streaming(
        (request, _) async => throw http.ClientException('offline'),
      );

      final result = await CloudinaryService(client: client).uploadFile(
        file: tinyPng(),
        kind: MediaKind.image,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('offline'));
    });
  });
}
