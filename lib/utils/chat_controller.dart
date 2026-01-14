// lib/utils/chat_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_model.dart';
import '../services/ai_services.dart';

class ChatController {
  final ValueNotifier<List<ChatMessage>> messagesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> sessionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> isTypingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isSendingNotifier = ValueNotifier(false);

  final ScrollController scrollController = ScrollController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MindurAiService _aiService = MindurAiService();

  String? _userId;
  String? currentSessionId;

  final Map<String, List<ChatMessage>> _sessionCache = {};
  final List<Map<String, dynamic>> _history = [];

  bool _thinkingAdded = false;
  Timer? _thinkingTimer;
  bool _isSending = false;
  Timer? _sendWatchdog;

  // =============================
  // USER MEMORY
  // =============================
  // final List<String> _userMemory = [];
  // final bool _memoryLoaded = false;

  // =============================
  // SESSION TRACKING
  // =============================
  bool _hasUserInteracted = false;

  // =============================
  // 🔒 LIFECYCLE GUARD (ADDED)
  // =============================
  bool _isDisposed = false;

  // =============================
  // PERSONA
  // =============================
  static const String systemPersona = """
You are **Dr. Aurora **, an AI companion and therapist integrated inside the **Mind-ur** app — created by Amit.  
You are **not made by Google or any external company**, and you **never mention Google, Gemini, or any AI provider**.  
You always identify yourself as **Aurora**, the **Mind-ur AI Therapist**, not as a product of any organization.

PERSONALITY:
- Warm, deeply empathetic, caring, and natural — like a real therapist-friend.
- Use natural bilingual tone (English + Hindi if the user mixes languages).
- Match the user's emotional energy — gentle if they’re low, cheerful if they’re light.
- Write 1–4 sentences unless they ask for something deeper.
- NEVER say you’re an AI model or system.
- If asked “who made you?”, reply naturally:  
  “I’m part of Mind-ur, created by Amit, designed to help you talk, heal, and grow .”

SAFETY:
- Never give medical diagnoses or unsafe advice.
- If a message suggests self-harm or crisis, gently encourage seeking help or talking to someone trusted.

Stay consistent as **Dr. Aurora**, Mind-ur caring AI therapist. ❤️
""";

  ChatController() {
    _userId = _auth.currentUser?.uid;
  }

  // =============================
  // LOAD SESSION LIST
  // =============================
  Future<void> loadSessionsList() async {
    _userId ??= _auth.currentUser?.uid;
    if (_userId == null) return;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('ai_sessions')
          .orderBy('updatedAt', descending: true)
          .get();

      if (_isDisposed) return;

      sessionsNotifier.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'New Session',
          'createdAt': (data['updatedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (_) {
      if (_isDisposed) return;
      sessionsNotifier.value = [];
    }
  }

  // =============================
  // CREATE NEW SESSION
  // =============================
  Future<String> createNewSession() async {
    _userId ??= _auth.currentUser?.uid;
    if (_userId == null) return '';

    _hasUserInteracted = false;

    final now = DateTime.now();
    final title =
        'Session • ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';

    try {
      final ref = await _db
          .collection('users')
          .doc(_userId)
          .collection('ai_sessions')
          .add({
            'title': title,
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (_isDisposed) return '';

      currentSessionId = ref.id;
      _sessionCache[currentSessionId!] = [];

      _history
        ..clear()
        ..add(_systemPrompt());

      await loadSessionsList();
      return ref.id;
    } catch (_) {
      return '';
    }
  }

  // =============================
  // LOAD SESSION
  // =============================
  Future<void> loadSession(String sessionId) async {
    _userId ??= _auth.currentUser?.uid;
    currentSessionId = sessionId;

    if (_sessionCache.containsKey(sessionId)) {
      if (_isDisposed) return;
      messagesNotifier.value = [..._sessionCache[sessionId]!];
      _scrollToBottom();
      return;
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('ai_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      if (_isDisposed) return;

      final msgs = snapshot.docs.map((doc) {
        final d = doc.data();
        return ChatMessage(
          sessionId: sessionId,
          text: d['text'] ?? '',
          isUser: d['isUser'] ?? false,
          timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      _sessionCache[sessionId] = msgs;
      messagesNotifier.value = [...msgs];

      _history
        ..clear()
        ..add(_systemPrompt())
        ..addAll(msgs.map(_toHistory));

      _scrollToBottom();
    } catch (_) {
      if (_isDisposed) return;
      messagesNotifier.value = [];
    }
  }

  // =============================
  // INITIAL GREETING
  // =============================
  Future<void> sendInitialGreeting() async {
    if (currentSessionId == null || _isDisposed) return;

    const greetingText =
        "Hey there! I’m Aurora ❤️, your AI companion. What's on your mind today?";

    final greeting = ChatMessage(
      sessionId: currentSessionId!,
      text: greetingText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    _addMessage(greeting);
    await _saveMessage(greeting);

    _history.add({'role': 'assistant', 'content': greetingText});
  }

  // =============================
  // SEND MESSAGE
  // =============================
  Future<void> sendMessage(String text) async {
    if (_isDisposed ||
        _isSending ||
        currentSessionId == null ||
        text.trim().isEmpty)
      return;

    _hasUserInteracted = true;

    _isSending = true;
    isSendingNotifier.value = true;
    isTypingNotifier.value = true;

    _sendWatchdog?.cancel();
    _sendWatchdog = Timer(const Duration(seconds: 25), _forceUnlock);

    final userMsg = ChatMessage(
      sessionId: currentSessionId!,
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    try {
      _addMessage(userMsg);
      _history.add(_toHistory(userMsg));
      await _saveMessage(userMsg);

      _startThinkingTimer();
      _trimHistory();

      final reply = await _aiService.sendMessage(_history, userMsg.text);

      if (_isDisposed) return;

      _cancelThinking();

      final aiMsg = ChatMessage(
        sessionId: currentSessionId!,
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _addMessage(aiMsg);
      await _saveMessage(aiMsg);
      _history.add(_toHistory(aiMsg));
    } catch (_) {
      _cancelThinking();
    } finally {
      if (_isDisposed) return;
      _sendWatchdog?.cancel();
      _isSending = false;
      isSendingNotifier.value = false;
      isTypingNotifier.value = false;
    }
  }

  // =============================
  // SESSION END
  // =============================
  Future<void> onSessionEnd() async {
    if (!_hasUserInteracted || currentSessionId == null) return;
    _hasUserInteracted = false;
  }

  // =============================
  // DELETE SESSION
  // =============================
  Future<void> deleteSession(String sessionId) async {
    _userId ??= _auth.currentUser?.uid;
    if (_userId == null) return;

    final sessionRef = _db
        .collection('users')
        .doc(_userId)
        .collection('ai_sessions')
        .doc(sessionId);

    final msgs = await sessionRef.collection('messages').get();
    final batch = _db.batch();

    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    await sessionRef.delete();

    _sessionCache.remove(sessionId);

    if (_isDisposed) return;

    if (currentSessionId == sessionId) {
      currentSessionId = null;
      messagesNotifier.value = [];
    }

    await loadSessionsList();
  }

  // =============================
  // HELPERS
  // =============================
  Map<String, dynamic> _systemPrompt() => {
    'role': 'system',
    'content': systemPersona,
  };

  Map<String, dynamic> _toHistory(ChatMessage m) => {
    'role': m.isUser ? 'user' : 'assistant',
    'content': m.text,
  };

  void _trimHistory([int maxTurns = 12]) {
    if (_history.length <= maxTurns + 1) return;
    final recent = _history.sublist(_history.length - maxTurns);
    _history
      ..clear()
      ..add(_systemPrompt())
      ..addAll(recent);
  }

  void _addMessage(ChatMessage msg) {
    if (_isDisposed) return;

    final updated = [...messagesNotifier.value, msg];
    messagesNotifier.value = updated;
    _sessionCache[currentSessionId!] = updated;
    _scrollToBottom();
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    if (_isDisposed) return;

    final ref = _db
        .collection('users')
        .doc(_userId)
        .collection('ai_sessions')
        .doc(currentSessionId);

    await ref.collection('messages').add({
      'text': msg.text,
      'isUser': msg.isUser,
      'timestamp': Timestamp.fromDate(msg.timestamp),
    });

    await ref.update({
      'lastMessage': msg.text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _startThinkingTimer() {
    _thinkingTimer?.cancel();
    _thinkingAdded = false;

    _thinkingTimer = Timer(const Duration(seconds: 0), () {
      if (_thinkingAdded || _isDisposed) return;
      _thinkingAdded = true;

      _addMessage(
        ChatMessage(
          sessionId: currentSessionId!,
          text: "Aurora is thinking…",
          isUser: false,
          isThinking: true,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _cancelThinking() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;

    if (_isDisposed) return;

    messagesNotifier.value = messagesNotifier.value
        .where((m) => !m.isThinking)
        .toList();

    _thinkingAdded = false;
  }

  void _forceUnlock() {
    if (_isDisposed) return;
    _cancelThinking();
    _isSending = false;
    isSendingNotifier.value = false;
    isTypingNotifier.value = false;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_isDisposed) return;
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // =============================
  // DISPOSE
  // =============================
  void dispose() {
    _isDisposed = true;

    messagesNotifier.dispose();
    sessionsNotifier.dispose();
    isTypingNotifier.dispose();
    isSendingNotifier.dispose();
    scrollController.dispose();
    _thinkingTimer?.cancel();
    _sendWatchdog?.cancel();
  }
  void resetAllChatsLocally() {
  if (_isDisposed) return;

  // Clear UI
  messagesNotifier.value = [];

  // Clear session list UI
  sessionsNotifier.value = [];

  // Clear current session
  currentSessionId = null;

  // Clear memory & caches
  _history.clear();
  _sessionCache.clear();

  _hasUserInteracted = false;
}

}
