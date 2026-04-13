import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MindurAiService {
  /// Backend URL depending on device
  /// Android Emulator -> 10.0.2.2
  /// iOS Simulator -> localhost
  /// Real Device -> replace with your PC IP
  static const String _baseUrl = "https://mindur-backend.onrender.com";
  static String get _endpoint => "$_baseUrl/ai/chat";

  /// Send message to Mindur backend AI
  Future<String> sendMessage(
    List<Map<String, dynamic>> history,
    String userMessage,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": userMessage,
              "history": history
                  .map(
                    (m) => {"role": m["role"], "content": m["content"] ?? ""},
                  )
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (kDebugMode) {
        debugPrint("🧠 Mindur backend status: ${response.statusCode}");
      }

      if (response.statusCode != 200) {
        throw Exception("Backend error ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      final reply = data["reply"]?.toString().trim();

      if (reply == null || reply.isEmpty) {
        return "I'm here with you. Want to say a little more?";
      }

      return reply;
    } on SocketException {
      throw Exception("Cannot connect to Mindur AI server");
    } on HttpException {
      throw Exception("Server error while contacting AI");
    } on FormatException {
      throw Exception("Invalid response from AI server");
    } catch (e) {
      throw Exception("AI request failed: $e");
    }
  }
}
