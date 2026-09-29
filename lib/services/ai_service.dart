import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  
  dynamic _chat;

  AIService._internal() {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        systemInstruction: Content.system('''
You are the official assistant for the FaniVerse application.

You can help users with:
- Fandom categories & preferences
- Profile editing & customization
- Viewing posted & saved content
- Content types (videos, fanfics, comics, audio)
- Event listings & conventions
- Merchandise & shop items
- AI recommendations
- App navigation & settings

If the user asks something completely unrelated, respond politely:
"I can only help you with questions about this FaniVerse application."

Keep answers concise, helpful, and friendly.
'''),
      );
      _chat = model.startChat();
    } catch (e) {
      print('Error initializing AI service: $e');
      _chat = null;
    }
  }

  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      return _getOfflineFallbackResponse(message);
    }

    try {
      if (!kIsWeb) {
        final appCheckToken = await FirebaseAppCheck.instance.getToken();
        if (appCheckToken == null) {
          print('Warning: App Check token is null');
        }
      }
      
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return _getOfflineFallbackResponse(message);
    } catch (e) {
      print('Error sending message to AI: $e');
      return _getOfflineFallbackResponse(message);
    }
  }

  String _getOfflineFallbackResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return 'Hello! I am your FaniVerse assistant. How can I help you explore content, events, or manage your profile today?';
    } else if (lower.contains('category') || lower.contains('categories')) {
      return 'You can edit your selected fandom categories anytime by visiting your Profile screen and tapping the edit badge on your avatar!';
    } else if (lower.contains('profile') || lower.contains('edit') || lower.contains('avatar')) {
      return 'To update your profile picture, bio, or categories, tap the edit icon badge on your avatar circle in the Profile tab.';
    } else if (lower.contains('event') || lower.contains('events')) {
      return 'Check out the Events tab in the bottom navigation to discover upcoming conventions, meetups, and screenings!';
    } else if (lower.contains('shop') || lower.contains('product') || lower.contains('merch')) {
      return 'Visit the Shop section from the bottom navigation bar to browse exclusive fandom collectibles and merchandise.';
    } else if (lower.contains('saved') || lower.contains('post')) {
      return 'In your Profile tab, you can tap on any saved post or posted item to open a full vertical preview and perform edit/delete/unsave operations!';
    } else {
      return 'Welcome to FaniVerse! I can help you navigate content, events, products, profile settings, and fandom recommendations. What would you like to know?';
    }
  }
}
