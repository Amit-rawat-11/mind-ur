import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  // ✅ ADD THIS
  final bool isThinking;

  ChatMessage({
    this.id = '',
    required this.sessionId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isThinking = false, // default = normal message
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      // ❌ do NOT store isThinking in Firestore
    };
  }

  factory ChatMessage.fromMap(
    Map<String, dynamic> map,
    String sessionId, [
    String? id,
  ]) {
    return ChatMessage(
      id: id ?? '',
      sessionId: sessionId,
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isThinking: false, // Firestore messages are never thinking
    );
  }
}
