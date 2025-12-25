import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'api_config_service.dart';

class MindurAiService {
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  static final _apiKey = ApiConfigService.openRouterKey!;
  static const String _primaryModel ='google/gemini-2.0-flash-exp:free';

  static const String _fallbackModel = 'mistralai/mistral-7b-instruct';  

  static const String _plainTextSystemPrompt = '''
You are an AI assistant inside the Mind-ur app.
You are not a real person.

Do not invent names.
Do not address the user by any name unless the user explicitly provides one.
Do not roleplay identity beyond being an AI assistant.
Do not repeat sentences or paragraphs.

Emojis are allowed but must be used sparingly.
Use at most one emoji per response.
Only use an emoji if it genuinely adds warmth.
Never repeat emojis or use emoji chains.

Reply in plain, natural text only.
Do not use markdown or special formatting.
Be supportive, concise, and calm.
''';

  Future<String> sendMessage(
    List<Map<String, dynamic>> history,
    String userMessage,
  ) async {
    if (_apiKey.isEmpty) {
      throw Exception('OPENROUTER_API_KEY missing');
    }

    // ✅ DO NOT redefine persona here
    // Persona comes ONLY from ChatController history

    final messages = [
      {'role': 'system', 'content': _plainTextSystemPrompt},
      ...history.map((m) => {'role': m['role'], 'content': m['content'] ?? ''}),
    ];

    return await _callModel(_primaryModel, messages).catchError((_) async {
      debugPrint('⚠️ Primary model failed. Using fallback.');
      return await _callModel(_fallbackModel, messages);
    });
  }

  Future<String> _callModel(
    String model,
    List<Map<String, dynamic>> messages,
  ) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://mindur.app',
        'X-Title': 'Mind-ur',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.65,
        'max_tokens': 500,
      }),
    );

    debugPrint('🤖 $model → HTTP ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception('OpenRouter error ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final reply = data['choices']?[0]?['message']?['content']
        ?.toString()
        .trim();

    return (reply == null || reply.isEmpty)
        ? "I’m here with you. Want to say a little more?"
        : reply;
  }
}
