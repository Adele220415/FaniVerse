import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../models/content_item.dart';
import '../services/auth_service.dart';
import '../services/engagement_service.dart';
import '../widgets/media_slideshow.dart';

class ContentDetailScreen extends StatefulWidget {
  final ContentItem item;
  final VoidCallback? onBack;

  const ContentDetailScreen({
    super.key,
    required this.item,
    this.onBack,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final EngagementService _engagement = EngagementService();

  bool _isSaved = false;
  bool _isLiked = false;
  bool _isCheckingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadMyInteractions();
    _incrementView();
  }

  /// Count this view once per user, ever. The transaction checks the user's
  /// own `interactions` document, so reopening the post - or opening it on a
  /// second device - does not inflate the number.
  Future<void> _incrementView() async {
    final result = await _engagement.registerView(widget.item.id);
    if (!result.isSuccess) {
      debugPrint('view not recorded: ${result.error}');
    }
  }

  Future<void> _loadMyInteractions() async {
    final interactions = await _engagement.loadInteractions();
    if (!mounted) return;
    setState(() {
      _isSaved = interactions.saved.contains(widget.item.id);
      _isLiked = interactions.liked.contains(widget.item.id);
      _isCheckingSaved = false;
    });
  }

  Future<void> _toggleLike() async {
    final result = await _engagement.toggleLike(widget.item.id);
    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not update the like')),
      );
      return;
    }
    setState(() => _isLiked = result.data!);
  }

  Future<void> _toggleSaved() async {
    final result = await _engagement.toggleSave(widget.item.id);
    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not update your saved list')),
      );
      return;
    }

    setState(() => _isSaved = result.data!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isSaved ? 'Item saved' : 'Item removed from saved list')),
    );
  }

  /// The overflow menu in the app bar. Editing and deleting are destructive or
  /// disruptive, so they are behind a three-dot menu instead of sitting as
  /// loose icons beside the post's own controls.
  Widget _buildOverflowMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      color: AppColors.surface,
      tooltip: 'More',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditContentDialog();
          case 'delete':
            _deleteContent();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
              SizedBox(width: 12),
              Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppColors.error),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteContent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Content', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to delete this item? This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('content').doc(widget.item.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content deleted successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete content: $e')),
          );
        }
      }
    }
  }

  void _showEditContentDialog() {
    final titleController = TextEditingController(text: widget.item.title);
    final descController = TextEditingController(text: widget.item.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit Content', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = titleController.text.trim();
                final newDesc = descController.text.trim();
                if (newTitle.isNotEmpty) {
                  await _firestore.collection('content').doc(widget.item.id).update({
                    'title': newTitle,
                    'description': newDesc,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post updated successfully')),
                    );
                    Navigator.pop(context, true); // Return true to indicate update
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    // `creator` is a display name, so comparing it to a uid never matched and
    // the author controls were hidden on your own posts. `authorId` is the uid
    // taken from the `author` reference; the name is only a legacy fallback.
    final authorId = widget.item.authorId.isNotEmpty ? widget.item.authorId : widget.item.creator;
    final isOwned = uid != null && uid == authorId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.item.title, style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        // Author actions live behind a single overflow menu rather than
        // sitting next to the post's own controls.
        actions: [
          if (isOwned) _buildOverflowMenu(context),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.media.isNotEmpty) ...[
              // Renders the full slideshow: images, video with play/pause,
              // seek, volume and fullscreen, and audio with its own controls.
              // `intrinsicAspect` sizes the box to each item's real
              // proportions, so a portrait photo is not cropped to 16:9.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaSlideshow(
                  media: widget.item.media,
                  intrinsicAspect: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.item.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOwned) ...[
                  // Author actions are in the app bar's overflow menu now.
                  const SizedBox.shrink(),
                ] else if (!_isCheckingSaved) ...[
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? AppColors.primary : Colors.white,
                    ),
                    onPressed: _toggleSaved,
                    tooltip: _isSaved ? 'Remove from saved' : 'Save',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.description.isNotEmpty ? widget.item.description : 'No description provided.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            // Follows the document, so a like or view from another device
            // shows up here without a refresh.
            StreamBuilder<ContentCounts>(
              stream: _engagement.watchCounts(widget.item.id),
              builder: (context, snapshot) {
                final counts = snapshot.data;
                return Row(
                  children: [
                    // White outline until liked, then filled red.
                    InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: _isLiked ? Colors.red : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${counts?.likes ?? widget.item.likes} likes',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, size: 18, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          '${counts?.views ?? widget.item.views} views',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
