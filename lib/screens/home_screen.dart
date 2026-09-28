import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../services/auth_service.dart';
import '../models/content_item.dart';
import '../models/user_model.dart';
import '../services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AIService _aiService;
  final Random _random = Random();
  final ScrollController _scrollController = ScrollController();

  UserModel? _userModel;
  List<ContentItem> _items = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _viewedItems = {};
  final Set<String> _likedItems = {};
  final Set<String> _savedItems = {};
  
  // Chatbot state
  bool _isChatVisible = false;
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
    _loadUserData();
    _loadUserInteractions();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
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
      }
    }
  }

  Future<void> _loadUserInteractions() async {
    final uid = widget.authService.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['liked'] == true) _likedItems.add(doc.id);
        if (data['saved'] == true) _savedItems.add(doc.id);
        if (data['viewed'] == true) _viewedItems.add(doc.id);
      }
    } catch (_) {}
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
        
        // Handle categories field - could be List or String
        List<String> categoriesList = [];
        if (data['categories'] is List) {
          try {
            categoriesList = List<String>.from(
              (data['categories'] as List).map((e) => e.toString()).toList()
            );
          } catch (e) {
            categoriesList = [];
          }
        } else if (data['categories'] is String) {
          categoriesList = [data['categories'] as String];
        } else if (data['category'] is String) {
          categoriesList = [data['category'] as String];
        }
        
        // Safely extract string fields
        String title = '';
        try {
          final titleData = data['title'];
          if (titleData is String) {
            title = titleData;
          } else if (titleData != null) {
            title = titleData.toString();
          }
        } catch (e) {
          title = '';
        }
        
        String type = '';
        try {
          final typeData = data['type'];
          if (typeData is String) {
            type = typeData;
          } else if (typeData != null) {
            type = typeData.toString();
          }
        } catch (e) {
          type = '';
        }
        
        String imageUrl = '';
        try {
          final imageUrlData = data['imageUrl'];
          if (imageUrlData is String) {
            imageUrl = imageUrlData;
          } else if (imageUrlData != null) {
            imageUrl = imageUrlData.toString();
          }
        } catch (e) {
          imageUrl = '';
        }
        
        return ContentItem(
          id: doc.id,
          title: title,
          category: categoriesList.isNotEmpty ? categoriesList.first : '',
          categories: categoriesList,
          type: type,
          imageUrl: imageUrl,
          likes: (data['likes'] as num?)?.toInt() ?? 0,
          views: (data['views'] as num?)?.toInt() ?? 0,
          comments: (data['comments'] as num?)?.toInt() ?? 0,
          saved: (data['saved'] as num?)?.toInt() ?? 0,
        );
      }).whereType<ContentItem>().toList();

      // Sort by trending score with randomization
      items.sort((a, b) {
        final scoreA = a.trendingScore + _random.nextDouble() * 50;
        final scoreB = b.trendingScore + _random.nextDouble() * 50;
        return scoreB.compareTo(scoreA);
      });

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveInteraction(String docId, String field, bool value) async {
    final uid = widget.authService.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .doc(docId)
          .set({field: value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _incrementView(String docId) async {
    if (_viewedItems.contains(docId)) return;
    _viewedItems.add(docId);

    setState(() {
      final idx = _items.indexWhere((i) => i.id == docId);
      if (idx != -1) {
        final item = _items[idx];
        _items[idx] = ContentItem(
          id: item.id,
          title: item.title,
          category: item.category,
          categories: item.categories,
          type: item.type,
          imageUrl: item.imageUrl,
          likes: item.likes,
          views: item.views + 1,
          comments: item.comments,
          saved: item.saved,
        );
      }
    });

    try {
      await _firestore.collection('content').doc(docId).update({
        'views': FieldValue.increment(1),
      });
      await _saveInteraction(docId, 'viewed', true);
    } catch (_) {}
  }

  Future<void> _toggleLike(String docId) async {
    final isLiked = _likedItems.contains(docId);
    final delta = isLiked ? -1 : 1;

    setState(() {
      if (isLiked) {
        _likedItems.remove(docId);
      } else {
        _likedItems.add(docId);
      }
      final idx = _items.indexWhere((i) => i.id == docId);
      if (idx != -1) {
        final item = _items[idx];
        _items[idx] = ContentItem(
          id: item.id,
          title: item.title,
          category: item.category,
          categories: item.categories,
          type: item.type,
          imageUrl: item.imageUrl,
          likes: item.likes + delta,
          views: item.views,
          comments: item.comments,
          saved: item.saved,
        );
      }
    });

    try {
      await _firestore.collection('content').doc(docId).update({
        'likes': FieldValue.increment(delta),
      });
      await _saveInteraction(docId, 'liked', !isLiked);
    } catch (_) {}
  }

  Future<void> _toggleSave(String docId) async {
    final isSaved = _savedItems.contains(docId);
    final delta = isSaved ? -1 : 1;

    setState(() {
      if (isSaved) {
        _savedItems.remove(docId);
      } else {
        _savedItems.add(docId);
      }
      final idx = _items.indexWhere((i) => i.id == docId);
      if (idx != -1) {
        final item = _items[idx];
        _items[idx] = ContentItem(
          id: item.id,
          title: item.title,
          category: item.category,
          categories: item.categories,
          type: item.type,
          imageUrl: item.imageUrl,
          likes: item.likes,
          views: item.views,
          comments: item.comments,
          saved: item.saved + delta,
        );
      }
    });

    try {
      await _firestore.collection('content').doc(docId).update({
        'saved': FieldValue.increment(delta),
      });
      await _saveInteraction(docId, 'saved', !isSaved);
    } catch (_) {}
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
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFandomStories(),
                  _buildForYouSection(),
                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            ),
          ),
          
          // Chatbot overlay
          if (_isChatVisible) _buildChatInterface(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Home',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              // Chat toggle button
              IconButton(
                icon: Icon(
                  _isChatVisible ? Icons.close : Icons.chat_bubble_outline,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  setState(() {
                    _isChatVisible = !_isChatVisible;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: AppColors.textPrimary),
                onPressed: () {
                  // Navigate to profile
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFandomStories() {
    final categories = _userModel?.categories ?? AppCategories.all;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Fandom Stories',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryAvatar(category);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryAvatar(String category) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
            ),
            child: Center(
              child: Text(
                AppCategories.getIcon(category),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'For You',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: AppColors.error),
            ),
          )
        else if (_items.isEmpty)
          const Center(
            child: Text(
              'No content found. Select more categories to see content!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _buildContentCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    item.category[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '2h ago',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.type.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content image
          GestureDetector(
            onTap: () => _incrementView(item.id),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade800,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
            ),
          ),
          
          // Content details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                ),
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    _actionButton(
                      icon: _likedItems.contains(item.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      count: item.likes,
                      color: _likedItems.contains(item.id)
                          ? Colors.red
                          : AppColors.textSecondary,
                      onTap: () => _toggleLike(item.id),
                    ),
                    const SizedBox(width: 16),
                    _actionButton(
                      icon: Icons.comment_outlined,
                      count: item.comments,
                      color: AppColors.textSecondary,
                      onTap: () {
                        // Add comment functionality
                      },
                    ),
                    const SizedBox(width: 16),
                    _actionButton(
                      icon: _savedItems.contains(item.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      count: item.saved,
                      color: _savedItems.contains(item.id)
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
