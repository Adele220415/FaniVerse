import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../core/result.dart';
import 'cloudinary_service.dart';

/// Convenience wrapper around [ImagePicker] so the pickers can be swapped out
/// in tests without touching call sites.
///
/// Every method returns an [XFile] rather than a path. On the web the pickers
/// return a blob with no filesystem path behind it, so a `String` path is not
/// always available and `dart:io` is not usable.
class _PickerFacade {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    // imageQuality/maxWidth are applied by the native pickers. The web picker
    // ignores them, so the original bytes may be larger there.
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
  }

  Future<XFile?> pickVideo() {
    return _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<XFile?> pickAudio() async {
    // image_picker has no audio support, so audio goes through file_picker.
    // PlatformFile.xFile bridges to the in-memory bytes the web exposes.
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final picked = result?.files.single;
    return picked?.xFile;
  }
}

/// Handles the whole "user picked a file" journey: open the system picker,
/// send the bytes to Cloudinary, and (optionally) write the resulting URL to
/// Firestore.
class MediaUploadService {
  final CloudinaryService _cloudinary;
  final _PickerFacade _files = _PickerFacade();

  MediaUploadService({CloudinaryService? cloudinary}) : _cloudinary = cloudinary ?? CloudinaryService();

  CloudinaryService get cloudinary => _cloudinary;

  // ---------------------------------------------------------------------------
  // Pick + upload
  // ---------------------------------------------------------------------------

  /// Let the user choose an image, upload it, and return the Cloudinary URL.
  /// Returns `null` when the user cancels the picker.
  Future<Result<CloudinaryUpload?>> pickAndUploadImage({
    String folder = 'faniverse/images',
  }) =>
      _pickAndUpload(_files.pickImage, MediaKind.image, folder);

  /// Let the user choose a video, upload it, and return the Cloudinary URL.
  Future<Result<CloudinaryUpload?>> pickAndUploadVideo({
    String folder = 'faniverse/videos',
  }) =>
      _pickAndUpload(_files.pickVideo, MediaKind.video, folder);

  /// Let the user choose an audio file, upload it, and return the URL.
  Future<Result<CloudinaryUpload?>> pickAndUploadAudio({
    String folder = 'faniverse/audio',
  }) =>
      _pickAndUpload(_files.pickAudio, MediaKind.audio, folder);

  /// Upload a file that has already been obtained, skipping the picker.
  Future<Result<CloudinaryUpload>> uploadExisting({
    required XFile file,
    required MediaKind kind,
    String? folder,
  }) {
    return _cloudinary.uploadFile(
      file: file,
      kind: kind,
      folder: folder ?? 'faniverse/${kind.name}',
    );
  }

  Future<Result<CloudinaryUpload?>> _pickAndUpload(
    Future<XFile?> Function() picker,
    MediaKind kind,
    String folder,
  ) async {
    final XFile? file;
    try {
      file = await picker();
    } catch (e) {
      return Result.error('Could not open the file picker: $e');
    }

    // The user closed the picker without choosing anything. Not an error.
    if (file == null) {
      return Result.success(null);
    }

    final result = await _cloudinary.uploadFile(file: file, kind: kind, folder: folder);
    if (result.isSuccess) {
      return Result.success(result.data);
    }
    return Result.error(result.error ?? 'Upload failed');
  }

  // ---------------------------------------------------------------------------
  // Persisting URLs to Firestore
  // ---------------------------------------------------------------------------

  /// Write uploaded media URLs onto an existing `content` document.
  ///
  /// Only the URL lists that are non-null are written, so adding a cover image
  /// to a post that already has a video will not wipe the video list.
  Future<Result<void>> updateContentMedia({
    required String contentId,
    List<String>? imageUrls,
    List<String>? videoUrls,
    List<String>? audioUrls,
  }) async {
    final patch = <String, dynamic>{};

    if (imageUrls != null) {
      patch['imageUrl'] = imageUrls;
      // bannerUrl is the legacy field several readers still fall back to.
      if (imageUrls.isNotEmpty) patch['bannerUrl'] = imageUrls.first;
    }
    if (videoUrls != null) patch['videoUrl'] = videoUrls;
    if (audioUrls != null) patch['audioUrl'] = audioUrls;

    if (patch.isEmpty) {
      return Result.success(null);
    }

    try {
      await FirebaseFirestore.instance.collection('content').doc(contentId).update({
        ...patch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not save the media URLs: $e');
    }
  }

  /// Set the signed-in user's profile picture to the Cloudinary URL.
  Future<Result<void>> updateProfileImage(String url) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Result.error('You must be logged in to change your profile picture');
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImage': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.error('Could not save your profile picture: $e');
    }
  }
}
