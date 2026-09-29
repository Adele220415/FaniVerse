import 'package:firebase_ai/firebase_ai.dart';
import '../models/user_model.dart';
import '../models/content_item.dart';

// Export Recommendation class for use in other files
class Recommendation {
  final String type;
  final String category;
  final String title;
  final String description;
  final String reason;

  Recommendation({
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.reason,
  });
}

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  
  RecommendationService._internal();
  
  dynamic _chat;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        systemInstruction: Content.system('''
You are a personalized content recommendation system for a fan community app called FaniVerse.

Your role is to analyze user preferences and provide tailored recommendations for:
- Content (fanfics, videos, audio, comics, playlists)
- Events (conventions, meetups, screenings)
- Products (merchandise, figures, collectibles)

User preferences include:
- Selected fandom categories (Anime, K-Pop, Comics, Gaming, Books, Movies, TV Shows, Music, Sports, Art, Fashion, Technology, Science, History, Food, Travel, Photography)
- User interactions (likes, saves, views)
- User profile information

Provide recommendations in a structured format that can be easily parsed.

For each recommendation, include:
- Type (content/event/product)
- Category (fandom)
- Title/name
- Brief description
- Reason for recommendation (why this matches user interests)

Keep responses concise and focused on the user's specific interests.
'''),
      );
      _chat = model.startChat();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing recommendation service: $e');
      _chat = null;
    }
  }

  Future<List<Recommendation>> getContentRecommendations(
    UserModel user,
    List<ContentItem> viewedItems,
    List<ContentItem> likedItems,
    List<ContentItem> savedItems,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final categories = user.categories.join(', ');
      final prompt = '''
User Profile:
- Selected Fandom Categories: $categories
- Username: ${user.username}
- Bio: ${user.bio}

User Activity:
- Viewed ${viewedItems.length} items
- Liked ${likedItems.length} items
- Saved ${savedItems.length} items

Sample of liked content:
${likedItems.take(3).map((item) => '- ${item.title} (${item.category})').join('\n')}

Sample of saved content:
${savedItems.take(3).map((item) => '- ${item.title} (${item.category})').join('\n')}

Provide 5 personalized content recommendations strictly based on this user's selected categories ($categories).
Spread recommendations across different categories in their selected list ($categories). Do NOT include categories outside this list.

Format each recommendation as:
TYPE:content|CATEGORY:[category]|TITLE:[title]|DESCRIPTION:[description]|REASON:[reason]
''';

      if (_chat != null) {
        final response = await _chat.sendMessage(Content.text(prompt));
        final responseText = response.text ?? '';
        
        final items = _parseRecommendations(responseText, 'content', user.categories);
        if (items.isNotEmpty) return items;
      }
      return _getFallbackRecommendations(user, 'Anime', 'content');
    } catch (e) {
      print('Error getting content recommendations: $e');
      return _getFallbackRecommendations(user, 'Anime', 'content');
    }
  }

  Future<List<Recommendation>> getEventRecommendations(
    UserModel user,
    List<String> userCategories,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final categories = userCategories.join(', ');
      final prompt = '''
User Profile:
- Selected Fandom Categories: $categories
- Username: ${user.username}
- Bio: ${user.bio}

Provide 5 personalized event recommendations strictly based on this user's fandom interests ($categories).
Do NOT include any other categories not in their list. Spread across different categories in ($categories).

Format each recommendation as:
TYPE:event|CATEGORY:[category]|TITLE:[title]|DESCRIPTION:[description]|REASON:[reason]
''';

      if (_chat != null) {
        final response = await _chat.sendMessage(Content.text(prompt));
        final responseText = response.text ?? '';
        
        final items = _parseRecommendations(responseText, 'event', userCategories);
        if (items.isNotEmpty) return items;
      }
      return _getFallbackRecommendations(user, 'Anime', 'event');
    } catch (e) {
      print('Error getting event recommendations: $e');
      return _getFallbackRecommendations(user, 'Anime', 'event');
    }
  }

  Future<List<Recommendation>> getProductRecommendations(
    UserModel user,
    List<String> userCategories,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final categories = userCategories.join(', ');
      final prompt = '''
User Profile:
- Selected Fandom Categories: $categories
- Username: ${user.username}
- Bio: ${user.bio}

Provide 5 personalized product recommendations strictly based on this user's fandom interests ($categories).
Do NOT include any other categories not in their list. Spread across different categories in ($categories).

Format each recommendation as:
TYPE:product|CATEGORY:[category]|TITLE:[title]|DESCRIPTION:[description]|REASON:[reason]
''';

      if (_chat != null) {
        final response = await _chat.sendMessage(Content.text(prompt));
        final responseText = response.text ?? '';
        
        final items = _parseRecommendations(responseText, 'product', userCategories);
        if (items.isNotEmpty) return items;
      }
      return _getFallbackRecommendations(user, 'Anime', 'product');
    } catch (e) {
      print('Error getting product recommendations: $e');
      return _getFallbackRecommendations(user, 'Anime', 'product');
    }
  }

  List<Recommendation> _parseRecommendations(String responseText, String expectedType, List<String> userCategories) {
    final recommendations = <Recommendation>[];
    final lines = responseText.split('\n');
    final validCategories = userCategories.map((c) => c.toLowerCase().trim()).toSet();
    
    for (final line in lines) {
      if (line.startsWith('TYPE:')) {
        try {
          final parts = line.split('|');
          if (parts.length >= 5) {
            final type = parts[0].replaceAll('TYPE:', '').trim();
            final category = parts[1].replaceAll('CATEGORY:', '').trim();
            final title = parts[2].replaceAll('TITLE:', '').trim();
            final description = parts[3].replaceAll('DESCRIPTION:', '').trim();
            final reason = parts[4].replaceAll('REASON:', '').trim();
            
            // Only accept recommendation if its category matches user selected categories
            if (validCategories.isEmpty || validCategories.contains(category.toLowerCase())) {
              recommendations.add(Recommendation(
                type: type,
                category: category,
                title: title,
                description: description,
                reason: reason,
              ));
            }
          }
        } catch (e) {
          print('Error parsing recommendation line: $line');
        }
      }
    }
    
    return recommendations;
  }

  List<Recommendation> _getFallbackRecommendations(UserModel user, String defaultCategory, String type) {
    final userCats = user.categories.isNotEmpty ? user.categories : [defaultCategory];
    
    if (type == 'content') {
      final list = <Recommendation>[];
      for (int i = 0; i < userCats.length; i++) {
        final cat = userCats[i];
        list.add(Recommendation(
          type: 'content',
          category: cat,
          title: 'Trending $cat Fan Arts & Lore',
          description: 'Explore community top-voted discussions, fan theories, and artwork for $cat.',
          reason: 'Matches your selected category: $cat.',
        ));
        if (list.length >= 5) break;
      }
      if (list.length < 3 && userCats.isNotEmpty) {
        final cat = userCats[0];
        list.add(Recommendation(
          type: 'content',
          category: cat,
          title: 'Top Community Discussions in $cat',
          description: 'Join thousands of fans discussing latest updates in $cat.',
          reason: 'Popular in your $cat category.',
        ));
      }
      return list;
    } else if (type == 'event') {
      return userCats.map((cat) => Recommendation(
        type: 'event',
        category: cat,
        title: '$cat Annual Fan Expo',
        description: 'Meet cosplayers, creators, and fellow fans at this upcoming $cat gathering.',
        reason: 'Popular event in $cat.',
      )).take(4).toList();
    } else {
      return userCats.map((cat) => Recommendation(
        type: 'product',
        category: cat,
        title: 'Limited Edition $cat Collectible',
        description: 'Exclusive merchandise badge & figurine set for $cat fans.',
        reason: 'Recommended for fans of $cat.',
      )).take(4).toList();
    }
  }
}
