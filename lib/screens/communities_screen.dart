import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/fv_screen.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';

/// Browse every community, with search and a category filter.
///
/// The designs put communities behind Explore; here it is a list screen reached
/// from the Explore header, which keeps the five-tab bottom bar intact.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key, this.service});

  final CommunityService? service;

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final CommunityService _service = widget.service ?? CommunityService();

  List<Community> _all = const [];
  Set<String> _joined = const {};
  String _query = '';
  String _category = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _service.watchCommunities().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _all = list;
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

    _service.watchMemberships().listen((ids) {
      if (mounted) setState(() => _joined = ids);
    });
  }

  List<Community> get _visible => _service.filter(_all, _query, category: _category);

  List<String> get _categories {
    final found = _all.map((c) => c.category).where((c) => c.isNotEmpty).toSet().toList()..sort();
    return found;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
    );
    if (created == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text(
          'New community',
          style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          FvScreenHeader(
            title: 'Communities',
            subtitle: 'Spaces for every fandom corner.',
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ),
          FvSearchField(
            controller: _searchController,
            hint: 'Search communities...',
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppThemeGutter, 10, AppThemeGutter, 0),
                children: [
                  FvPill(
                    label: 'All',
                    selected: _category.isEmpty,
                    onTap: () => setState(() => _category = ''),
                  ),
                  for (final category in _categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FvPill(
                        label: _titleCase(category),
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? FvEmptyState(
                        icon: Icons.cloud_off,
                        title: 'Could not load communities',
                        message: _error!.split('\n').first,
                        action: OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      )
                    : visible.isEmpty
                        ? FvEmptyState(
                            icon: _query.isEmpty ? Icons.groups : Icons.search_off,
                            title: _query.isEmpty ? 'No communities yet' : 'No matches',
                            message: _query.isEmpty
                                ? 'Be the first to start one.'
                                : 'Try a different search or category.',
                            action: _query.isEmpty
                                ? FvPrimaryButton(label: 'Create community', onPressed: _create)
                                : OutlinedButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _query = '';
                                        _category = '';
                                      });
                                    },
                                    child: const Text('Clear filters'),
                                  ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final community = visible[index];
                              return _CommunityCard(
                                community: community,
                                joined: _joined.contains(community.id),
                                onOpen: () => _open(community),
                                onToggleJoin: () => _toggleJoin(community),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _open(Community community) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CommunityDetailScreen(communityId: community.id, service: _service),
          ),
        )
        .then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _toggleJoin(Community community) async {
    final result = await _service.toggleMembership(community.id);
    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data! ? 'Joined ${community.name}' : 'Left ${community.name}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not update'), backgroundColor: AppColors.error),
      );
    }
  }

  String _titleCase(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// Local copy of the gutter so this file does not need the theme import.
const double AppThemeGutter = 20;

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.community,
    required this.joined,
    required this.onOpen,
    required this.onToggleJoin,
  });

  final Community community;
  final bool joined;
  final VoidCallback onOpen;
  final VoidCallback onToggleJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: community.imageUrl.isEmpty
                      ? const Icon(Icons.groups, color: AppColors.primaryLight, size: 24)
                      : Image.network(
                          community.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              const Icon(Icons.groups, color: AppColors.primaryLight, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (community.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          community.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${community.memberCount} member${community.memberCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Join is a separate target from the card so tapping the row
                // opens the community without also joining.
                OutlinedButton(
                  onPressed: onToggleJoin,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: joined ? AppColors.primaryTint : AppColors.elevated,
                    foregroundColor: joined ? AppColors.primaryLight : AppColors.textPrimary,
                    side: BorderSide(color: joined ? AppColors.primary : AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(
                    joined ? 'Joined' : 'Join',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
