import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../core/constants/cloudinary_config.dart';
import '../core/result.dart';
import '../models/content_media.dart';
import '../services/cloudinary_service.dart';
import '../services/media_upload_service.dart';
import '../widgets/media_tray.dart';

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key, this.onPublished});

  /// Called after a post is written successfully.
  ///
  /// This screen is a tab inside an [IndexedStack], not a pushed route, so
  /// there is nothing to pop. Calling `Navigator.pop` here would unwind the
  /// app's only route and leave a blank white page. The shell supplies this
  /// callback to move the user back to a real screen instead.
  final VoidCallback? onPublished;

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final MediaUploadService _media = MediaUploadService();

  /// The slideshow, in order. This is what gets written to the `media` array.
  final List<ContentMedia> _items = [];

  /// Fallback for pasting URLs by hand when Cloudinary is unavailable.
  final _manualUrlController = TextEditingController();
  String _manualType = 'image';

  /// How many uploads of each kind are in flight, so the buttons can disable
  /// individually instead of locking the whole form.
  final Set<MediaKind> _uploading = {};

  String _selectedCategory = 'anime';
  bool _isLoading = false;

  bool get _isUploading => _uploading.isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _manualUrlController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Uploads
  // ---------------------------------------------------------------------------

  Future<void> _addImages() => _add(
        MediaKind.image,
        () => _media.pickAndUploadImage(folder: 'faniverse/content/images'),
      );

  Future<void> _addVideos() => _add(
        MediaKind.video,
        () => _media.pickAndUploadVideo(folder: 'faniverse/content/videos'),
      );

  Future<void> _addAudio() => _add(
        MediaKind.audio,
        () => _media.pickAndUploadAudio(folder: 'faniverse/content/audio'),
      );

  Future<void> _add(
    MediaKind kind,
    Future<Result<CloudinaryUpload?>> Function() run,
  ) async {
    if (_uploading.contains(kind)) return;

    setState(() => _uploading.add(kind));
    final result = await run();
    if (!mounted) return;
    setState(() => _uploading.remove(kind));

    if (!result.isSuccess) {
      _toast(result.error ?? 'Upload failed', isError: true);
      return;
    }

    // Null means the picker was dismissed without choosing anything.
    final upload = result.data;
    if (upload == null) return;

    // Dimensions come from Cloudinary's own upload response and are stored with
    // the item, so the viewer can show it at its true proportions without
    // downloading and decoding it to find out.
    setState(() {
      _items.add(
        ContentMedia(
          type: kind.name,
          url: upload.url,
          width: upload.width,
          height: upload.height,
        ),
      );
    });
    _toast('${kind.label} added to your slideshow');
  }

  void _addManualUrl() {
    final url = _manualUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _items.add(ContentMedia(type: _manualType, url: url));
      _manualUrlController.clear();
    });
  }

  void _removeAt(int index) {
    setState(() => _items.removeAt(index));
  }

  /// [ReorderableListView] reports the destination index *before* the item is
  /// removed, so a downward move has to be decremented by one.
  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Publish
  // ---------------------------------------------------------------------------

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _toast('You must be logged in to create content.', isError: true);
        return;
      }

      String creatorName = 'Anonymous Fan';
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data != null) {
        creatorName = (data['username'] ?? data['name'] ?? user.displayName ?? creatorName).toString();
      }

      // The legacy single-URL fields are still written, because other screens
      // and older documents read them. The first image, video and audio of the
      // slideshow stand in for them.
      final imageUrls = _items.where((i) => i.isImage).map((i) => i.url).toList();
      final videoUrls = _items.where((i) => i.isVideo).map((i) => i.url).toList();
      final audioUrls = _items.where((i) => i.isAudio).map((i) => i.url).toList();

      // A post with no image still needs a bannerUrl, or grids that read it
      // directly will render blank.
      final banner = imageUrls.isNotEmpty
          ? imageUrls.first
          : (videoUrls.isNotEmpty ? videoUrls.first : (audioUrls.isNotEmpty ? audioUrls.first : ''));

      await FirebaseFirestore.instance.collection('content').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory.toLowerCase(),
        'categories': [_selectedCategory.toLowerCase()],
        'type': _inferType(),
        'media': _items.map((i) => i.toJson()).toList(),
        'imageUrl': imageUrls,
        'videoUrl': videoUrls,
        'audioUrl': audioUrls,
        'bannerUrl': banner,
        'author': FirebaseFirestore.instance.collection('users').doc(user.uid),
        'creator': creatorName,
        'status': 'published',
        'likes': 0,
        'views': 0,
        'comments': 0,
        'saved': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _resetForm();
      _toast('Content published successfully!');
      widget.onPublished?.call();
    } catch (e) {
      _toast('Failed to publish content: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// A slideshow is a `mixed` post; a single item keeps its own type so the old
  /// `type` field still means something.
  String _inferType() {
    if (_items.length > 1) return 'mixed';
    if (_items.isEmpty) return 'text';
    return _items.first.type;
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      _items.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final availableCategories = AppCategories.all;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Create Content'),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!CloudinaryConfig.isConfigured) _buildConfigWarning(),

              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: availableCategories.contains(_selectedCategory)
                    ? _selectedCategory
                    : (availableCategories.isNotEmpty ? availableCategories.first : 'anime'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
                items: availableCategories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 20),

              _sectionLabel('Slideshow', '${_items.length} item${_items.length == 1 ? '' : 's'}'),
              const SizedBox(height: 8),
              MediaTray(
                media: _items,
                onRemove: _removeAt,
                onReorder: _reorder,
                onPreview: (item) => showMediaPreview(context, item),
              ),
              const SizedBox(height: 12),
              _buildAddButtons(),
              const SizedBox(height: 12),
              _buildManualUrlRow(),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading || _isUploading ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isUploading ? 'Uploading...' : 'Publish Content',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAddButtons() {
    return Row(
      children: [
        Expanded(child: _addButton('Images', Icons.add_photo_alternate_outlined, MediaKind.image, _addImages)),
        const SizedBox(width: 8),
        Expanded(child: _addButton('Video', Icons.video_call_outlined, MediaKind.video, _addVideos)),
        const SizedBox(width: 8),
        Expanded(child: _addButton('Audio', Icons.mic_none, MediaKind.audio, _addAudio)),
      ],
    );
  }

  Widget _addButton(String label, IconData icon, MediaKind kind, VoidCallback onTap) {
    final busy = _uploading.contains(kind);
    return OutlinedButton.icon(
      onPressed: busy ? null : onTap,
      icon: busy
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildManualUrlRow() {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: DropdownButtonFormField<String>(
            initialValue: _manualType,
            isDense: true,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            ),
            items: const [
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
              DropdownMenuItem(value: 'audio', child: Text('Audio')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _manualType = val);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _manualUrlController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            onSubmitted: (_) => _addManualUrl(),
            decoration: const InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _addManualUrl,
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
          tooltip: 'Add URL',
        ),
      ],
    );
  }

  Widget _buildConfigWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${CloudinaryConfig.missingReason}\n\nYou can still publish by pasting URLs below.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
