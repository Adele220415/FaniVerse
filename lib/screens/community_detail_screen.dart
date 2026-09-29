import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/fv_list_card.dart';
import '../widgets/fv_screen.dart';

/// One community: its description, its discussions, and a post composer.
class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.communityId, this.service});

  final String communityId;
  final CommunityService? service;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late final CommunityService _service = widget.service ?? CommunityService();

  bool _isLoading = true;
  String? _error;
  Community? _community;
  List<CommunityPost> _posts = const [];
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _isLoading = true);

    _service.watchCommunity(widget.communityId).listen(
      (community) {
        if (!mounted) return;
        setState(() {
          _community = community;
          _isLoading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      },
    );

    _service.watchPosts(widget.communityId).listen((posts) {
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    });

    _service.watchMemberships().listen((ids) {
      if (!mounted) return;
      setState(() => _joined = ids.contains(widget.communityId));
    });
  }

  Future<void> _toggleJoin() async {
    final result = await _service.toggleMembership(widget.communityId);
    if (!mounted || result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Could not update'), backgroundColor: AppColors.error),
    );
  }

  Future<void> _compose() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ComposerSheet(communityId: widget.communityId, service: _service),
    );
    if (posted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final community = _community;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          community?.name ?? 'Community',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: community == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _compose,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.edit_outlined, color: AppColors.textOnPrimary, size: 20),
              label: const Text(
                'New post',
                style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? FvEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Could not load this community',
                  message: _error!.split('\n').first,
                  action: OutlinedButton(onPressed: _load, child: const Text('Retry')),
                )
              : community == null
                  ? const FvEmptyState(icon: Icons.error_outline, title: 'Community not found')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        _buildHero(community),
                        const SizedBox(height: 20),
                        FvSection(
                          title: 'Discussions',
                          trailing: Text(
                            '${_posts.length} post${_posts.length == 1 ? '' : 's'}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          children: [
                            if (_posts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: FvEmptyState(
                                  icon: Icons.forum_outlined,
                                  title: 'No posts yet',
                                  message: 'Start the first discussion.',
                                ),
                              )
                            else
                              for (final post in _posts) _buildPost(post),
                          ],
                        ),
                      ],
                    ),
    );
  }

  Widget _buildHero(Community community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: community.imageUrl.isEmpty
              ? const Icon(Icons.groups, size: 48, color: AppColors.primaryLight)
              : Image.network(
                  community.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) =>
                      const Icon(Icons.groups, size: 48, color: AppColors.primaryLight),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          community.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (community.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            community.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${community.memberCount} member${community.memberCount == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            _joined
                ? OutlinedButton(
                    onPressed: _toggleJoin,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.primaryTint,
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Joined'),
                  )
                : ElevatedButton(
                    onPressed: _toggleJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Join'),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildPost(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _service.togglePostLike(widget.communityId, post.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        post.authorName.isEmpty ? 'A fan' : post.authorName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.createdAt != null)
                      Text(
                        _relative(post.createdAt!),
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (post.title.isNotEmpty) ...[
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  post.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.mode_comment_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relative(DateTime then) {
    final diff = DateTime.now().difference(then);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

/// The post composer.
class _ComposerSheet extends StatefulWidget {
  const _ComposerSheet({required this.communityId, required this.service});

  final String communityId;
  final CommunityService service;

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty) return;
    setState(() => _busy = true);

    final result = await widget.service.createPost(
      communityId: widget.communityId,
      title: _titleController.text.trim(),
      content: _bodyController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not post'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New discussion',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'What is on your mind?',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FvPrimaryButton(
            label: 'Post',
            busy: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
