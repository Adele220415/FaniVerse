import 'package:firebase_ai/firebase_ai.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  
  AIService._internal() {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        systemInstruction: Content.system('''
You are the official assistant for this application.

You ONLY answer questions about this application.

You can help users with:

- Account
- Login
- Signup
- Profile
- Categories
- Content
- Events
- Merchandise
- Wishlist
- Recommendations
- Notifications
- Searching
- App navigation

Do NOT answer questions unrelated to this application.

If the user asks something unrelated, respond exactly:

"I can only help you with questions about this app."

Never invent features that do not exist in the application.
'''),
      );
      _chat = model.startChat();
    } catch (e) {
      print('Error initializing AI service: $e');
      _chat = null;
    }
  }

  late final dynamic _chat;

  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      return 'AI service is not available. Please check your Firebase configuration.';
    }

    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? 'No response received.';
    } catch (e) {
      print('Error sending message to AI: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }
}
