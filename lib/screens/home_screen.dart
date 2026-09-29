import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../services/engagement_service.dart';
import '../services/feed_service.dart';
import '../services/local_cache.dart';
import '../widgets/fv_screen.dart';
import '../widgets/media_slideshow.dart';
import '../widgets/offline_banner.dart';
import '../widgets/user_avatar.dart';
import '../services/auth_service.dart';
import '../models/content_item.dart';
import '../models/user_model.dart';
import '../services/ai_service.dart';
import '../services/recommendation_service.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'content_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AIService _aiService;
  late final RecommendationService _recommendationService;
  final ScrollController _scrollController = ScrollController();

  UserModel? _userModel;

  /// The unfiltered page as loaded from Firestore (or the offline cache).
  ///
  /// [_items] is the view of it under the current feed mode and category focus.
  /// Keeping the two apart means switching a pill re-sorts locally instead of
  /// re-querying, so the control feels instant and never changes the window of
  /// posts on screen.
  List<ContentItem> _allItems = [];

  /// What the feed currently renders: [_allItems] sorted and filtered.
  List<ContentItem> _items = [];

  bool _isLoading = true;

  /// Feed sort, surfaced as the segmented pill row above the list.
  FeedMode _feedMode = FeedMode.forYou;

  String? _error;
  final Set<String> _viewedItems = {};
  final Set<String> _likedItems = {};
  final Set<String> _savedItems = {};

  final EngagementService _engagement = EngagementService();
  StreamSubscription<Map<String, ContentCounts>>? _countsSub;

  /// SQLite mirror of the feed, read when the network is unavailable.
  final LocalCache _cache = LocalCache.instance;

  /// True when the feed on screen came from the local cache.
  bool _isOffline = false;
  DateTime? _cachedAt;
  
  // Chatbot state
  bool _isChatVisible = false;
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isTyping = false;
  
  // Recommendations state
  List<Recommendation> _recommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
    _recommendationService = RecommendationService();
    _loadUserData();
    _loadUserInteractions();
    _loadContent();
  }

  /// Called by [MainNavigationWrapper] when the user taps the Home tab again
  /// while already on it — triggers a fresh random selection.
  void refresh() {
    _loadContent();
  }

  /// Re-derives [_items] from [_allItems] under the current feed mode.
  void _reapplyFeedMode() {
    if (!mounted) return;

    final sorted = FeedSorter.sort(
      _allItems,
      _feedMode,
      preferredCategories: _preferredCategories(),
      random: Random(),
    );

    setState(() => _items = sorted);
  }

  /// The viewer's declared fandoms, lowercased for comparison.
  Set<String> _preferredCategories() {
    final cats = _userModel?.categories ?? const <String>[];
    return cats.map((c) => c.toLowerCase().trim()).where((c) => c.isNotEmpty).toSet();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
    _countsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = widget.authService.currentUser;
    if (user != null) {
      final result = await widget.authService.getUserData(user.uid);
      if (result.isSuccess && mounted) {
        setState(() {
          _userModel = result.data;
        });
        _loadContent();
      }
    }
  }

  Future<void> _loadUserInteractions() async {
    final interactions = await _engagement.loadInteractions();
    if (!mounted || interactions.viewed.isEmpty && interactions.liked.isEmpty && interactions.saved.isEmpty) {
      return;
    }

    setState(() {
      _viewedItems.addAll(interactions.viewed);
      _likedItems.addAll(interactions.liked);
      _savedItems.addAll(interactions.saved);
    });
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Query query = _firestore.collection('content');
      
      // Filter by user's categories if available
      if (_userModel != null && _userModel!.categories.isNotEmpty) {
        query = query.where('categories', arrayContainsAny: _userModel!.categories);
      }

      final snapshot = await query.limit(50).get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return ContentItem.fromFirebase(doc.id, data);
      }).whereType<ContentItem>().toList();

      // Sort by trending score with randomization
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
          _isOffline = false;
        });
        _reapplyFeedMode();
        // Start following the live counters for whatever is now on screen.
        _watchCounts();
      }

      // Cache the raw documents so the feed can be served offline later. The
      // doc id is merged in because it is not part of the document body.
      final cacheable = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        // doc.data() is Object? in this SDK, so narrow it before spreading.
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        cacheable.add(<String, dynamic>{'id': doc.id, ...data});
      }
      unawaited(_cache.saveContent(cacheable));

      // Load recommendations after content is loaded
      _loadRecommendations();
    } catch (e) {
      debugPrint('network feed load failed: $e');

      // The feed is unreadable without the network. Fall back to the local
      // cache rather than showing a dead end.
      final cached = await _cache.readContent(limit: 50);
      if (cached.isNotEmpty && mounted) {
        final items = cached
            .map((doc) => ContentItem.fromFirebase(doc['id'] as String, doc))
            .whereType<ContentItem>()
            .toList();

        final cachedAt = await LocalCache.instance.lastCachedAt();

        if (mounted) {
          setState(() {
            _allItems = items;
            _isLoading = false;
            _isOffline = true;
            _cachedAt = cachedAt;
          });
          _reapplyFeedMode();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    if (_userModel == null) return;
    
    setState(() {
      _isLoadingRecommendations = true;
    });
    
    try {
      final viewedItemsList = _items.where((item) => _viewedItems.contains(item.id)).toList();
      final likedItemsList = _items.where((item) => _likedItems.contains(item.id)).toList();
      final savedItemsList = _items.where((item) => _savedItems.contains(item.id)).toList();
      
      final recommendations = await _recommendationService.getContentRecommendations(
        _userModel!,
        viewedItemsList,
        likedItemsList,
        savedItemsList,
      );
      
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  /// Records a view through [EngagementService], which counts each user once
  /// ever rather than once per app launch.
  Future<void> _incrementView(String docId) async {
    if (_viewedItems.contains(docId)) return;

    final result = await _engagement.registerView(docId);
    if (!result.isSuccess) {
      debugPrint('view not recorded: ${result.error}');
      return;
    }

    // Optimistically reflect it; the snapshot below is the source of truth and
    // will correct this if two devices raced.
    setState(() {
      _viewedItems.add(docId);
      _patchCounts(docId, views: (_countFor(docId)?.views ?? 0) + 1);
    });
  }

  Future<void> _toggleLike(String docId) async {
    final result = await _engagement.toggleLike(docId);
    if (!result.isSuccess) {
      debugPrint('like not saved: ${result.error}');
      return;
    }

    final nowLiked = result.data!;
    setState(() {
      if (nowLiked) {
        _likedItems.add(docId);
      } else {
        _likedItems.remove(docId);
      }
    });
    // The count itself arrives via the live snapshot, so there is no
    // optimistic arithmetic to get wrong here.
  }

  Future<void> _toggleSave(String docId) async {
    final result = await _engagement.toggleSave(docId);
    if (!result.isSuccess) {
      debugPrint('save not saved: ${result.error}');
      return;
    }

    setState(() {
      if (result.data!) {
        _savedItems.add(docId);
      } else {
        _savedItems.remove(docId);
      }
    });
  }

  ContentCounts? _countFor(String docId) {
    for (final item in _items) {
      if (item.id == docId) {
        return ContentCounts(
          likes: item.likes,
          views: item.views,
          comments: item.comments,
          saved: item.saved,
        );
      }
    }
    return null;
  }

  /// Overwrite a post's counters in place, leaving every other field alone.
  void _patchCounts(String docId, {int? likes, int? views, int? comments, int? saved}) {
    final index = _items.indexWhere((i) => i.id == docId);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(
      likes: likes,
      views: views,
      comments: comments,
      saved: saved,
    );
  }

  /// Subscribe to the live counters for the posts currently on screen.
  ///
  /// Counts are patched onto the existing list instead of replacing it, so a
  /// like arriving from another user updates the number without re-sorting
  /// the feed out from under the reader.
  void _watchCounts() {
    _countsSub?.cancel();
    final ids = _items.map((i) => i.id).toList(growable: false);
    if (ids.isEmpty) return;

    _countsSub = _engagement.watchCountsFor(ids).listen((map) {
      if (!mounted || map.isEmpty) return;
      setState(() {
        map.forEach((docId, counts) {
          _patchCounts(
            docId,
            likes: counts.likes,
            views: counts.views,
            comments: counts.comments,
            saved: counts.saved,
          );
        });
      });
    });
  }

  Future<void> _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add(ChatMessage(text: message, isUser: true));
      _chatController.clear();
      _isTyping = true;
    });

    try {
      final response = await _aiService.sendMessage(message);
      setState(() {
        _chatMessages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
        ));
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Static header at top
          _buildHeader(),

          // Sits above the feed, outside the scroll area, so the offline state
          // stays visible while reading.
          OfflineBanner(
            cachedAt: _isOffline ? _cachedAt : null,
          ),

          // Main content scrollable area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildForYouSection(),
                  _buildRecommendationsSection(),
                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            ),
          ),
          
          // Chatbot overlay
          if (_isChatVisible) _buildChatInterface(),
        ],
      ),
      floatingActionButton: _isChatVisible
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isChatVisible = true;
                });
              },
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Username plus a one-line status.
  ///
  /// The time-of-day greeting moved to the login screen, where it belongs -
  /// greeting someone on a feed they open fifty times a day gets stale. The
  /// fan's own avatar leads the header so it is visible here too.
  Widget _buildHeader() {
    final name = _userModel?.username.isNotEmpty == true
        ? _userModel!.username
        : (_userModel?.name.isNotEmpty == true ? _userModel!.name : 'fan');

    return FvScreenHeader(
      title: name,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            userId: widget.authService.currentUser?.uid ?? '',
            imageUrl: _userModel?.profileImage ?? '',
            displayName: _userModel?.name ?? '',
            username: name,
            radius: 18,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(authService: widget.authService),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }


  /// The feed. No pill row here - sorting lives on Explore, so Home has a
  /// single, predictable order.
  Widget _buildForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && !_isOffline)
          FvEmptyState(
            icon: Icons.cloud_off,
            title: 'Could not load your feed',
            message: 'Check your connection and try again.',
            action: OutlinedButton(onPressed: _loadContent, child: const Text('Retry')),
          )
        else if (_items.isEmpty)
          const FvEmptyState(
            icon: Icons.auto_awesome,
            title: 'Nothing here yet',
            message: 'Pick more fandoms to fill this up.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildContentCard(_items[index]),
          ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    if (_recommendations.isEmpty && !_isLoadingRecommendations) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recommended for You',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingRecommendations)
          const Center(child: CircularProgressIndicator())
        else if (_recommendations.isEmpty)
          const Center(
            child: Text(
              'No recommendations yet. Keep interacting with content!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = _recommendations[index];
                return _buildRecommendationCard(recommendation);
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recommendation.category,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              recommendation.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              recommendation.reason,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a human-readable relative time string from a DateTime.
  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Slideshow for posts holding several media items.
  ///
  /// Delegates to [MediaSlideshow], which understands the ordered `media`
  /// list and renders video and audio with their own controls. The previous
  /// inline version only handled images and created a [PageController] that
  /// was never disposed.
  Widget _buildSlideshow(ContentItem item) {
    if (item.media.isEmpty) return _buildPlaceholderImage(item.type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: MediaSlideshow(media: item.media),
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    final authorName = item.creator.isNotEmpty ? item.creator : item.category;
    final timeAgo = _formatTimeAgo(item.createdAt);
    final contentType = item.type.toLowerCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(
                  // The feed only knows the author's display name, which is not
                  // an identity - so an empty id keeps the avatar inert instead
                  // of opening somebody's profile.
                  userId: item.authorId,
                  displayName: item.creator,
                  username: item.creator,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Content-type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        contentType == 'image'
                            ? Icons.image_outlined
                            : contentType == 'video'
                                ? Icons.videocam_outlined
                                : contentType == 'audio'
                                    ? Icons.audiotrack_outlined
                                    : contentType == 'mixed'
                                        ? Icons.collections_outlined
                                        : Icons.article_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contentType == 'mixed' ? 'SLIDESHOW' : item.type.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content area — slideshow for 'mixed', image otherwise
          GestureDetector(
            onTap: () {
              _incrementView(item.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentDetailScreen(item: item),
                ),
              );
            },
            child: _buildSlideshow(item),
          ),

          // Content details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                if (item.category.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Action buttons (no comment button)
                Row(
                  children: [
                    _actionButton(
                      icon: _likedItems.contains(item.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      count: item.likes,
                      // An unliked heart is a plain white outline; liking it
                      // fills it red.
                      color: _likedItems.contains(item.id)
                          ? Colors.red
                          : Colors.white,
                      onTap: () => _toggleLike(item.id),
                    ),
                    const SizedBox(width: 16),
                    _actionButton(
                      icon: _savedItems.contains(item.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      count: item.saved,
                      color: _savedItems.contains(item.id)
                          ? AppColors.primary
                          : Colors.white,
                      onTap: () => _toggleSave(item.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() => _isChatVisible = false);
                  },
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatMessages.length && _isTyping) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  );
                }
                final message = _chatMessages[index];
                return _buildChatMessage(message);
              },
            ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildPlaceholderImage(String type) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'video':
        icon = Icons.play_circle_outline;
        break;
      case 'audio':
        icon = Icons.headphones;
        break;
      case 'fanfic':
        icon = Icons.menu_book;
        break;
      case 'comic':
        icon = Icons.book;
        break;
      case 'playlist':
        icon = Icons.queue_music;
        break;
      default:
        icon = Icons.image;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
