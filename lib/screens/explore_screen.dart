import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../models/content_item.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  List<ContentItem> _allContent = [];
  List<ContentItem> _filteredContent = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _firestore.collection('content').get();

      _allContent = snapshot.docs.map((doc) {
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

      // Sort by trending score (descending) — most trending first
      _allContent.sort((a, b) {
        final scoreA = a.trendingScore + _random.nextDouble() * 20;
        final scoreB = b.trendingScore + _random.nextDouble() * 20;
        return scoreB.compareTo(scoreA);
      });

      _applyFilter();

      if (mounted) {
        setState(() {
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

  void _applyFilter() {
    List<ContentItem> items;

    if (_selectedFilter == 'All') {
      items = List.from(_allContent);
    } else {
      items = _allContent
          .where((item) => item.categories.contains(_selectedFilter))
          .toList();
    }

    // Re-sort by trending score after filtering
    items.sort((a, b) => b.trendingScore.compareTo(a.trendingScore));

    _filteredContent = items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Search bar
          _buildSearchBar(),
          
          // Filter chips
          _buildFilterChips(),
          
          // Content sections
          Expanded(
            child: _buildContentBody(),
          ),
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
            'Explore',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search communities, content...',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', ...AppCategories.all];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter();
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.3),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredContent.isEmpty) {
      return const Center(
        child: Text(
          'No content found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredContent.length,
            itemBuilder: (context, index) {
              final item = _filteredContent[index];
              return _buildContentCard(item);
            },
          ),
        ),
        const SizedBox(height: 80), // Space for bottom nav
      ],
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return Card(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                if (item.categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.categories.first,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 12, color: Colors.red),
                    const SizedBox(width: 2),
                    Text(
                      _formatCount(item.likes),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.visibility, size: 12, color: Colors.blue),
                    const SizedBox(width: 2),
                    Text(
                      _formatCount(item.views),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
