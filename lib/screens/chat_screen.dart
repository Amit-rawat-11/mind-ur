// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ kDebugMode
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure Google Fonts is available
import '../theme/colors.dart'; // Ensure MindurColors is available


import '../components/chat_screen_widgets/chat_drawer.dart';
import '../components/chat_screen_widgets/input_bar.dart';
import '../components/chat_screen_widgets/message_bubble.dart';
import '../models/chat_model.dart';
import '../services/analytics_service.dart';
import '../utils/chat_controller.dart';

/// ✅ Debug-only logger
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatController _controller = ChatController();
  final TextEditingController _inputController = TextEditingController();

  late AnimationController _fadeController;
  bool _showScrollFAB = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime _sessionStartTime;

  @override
  void initState() {
    super.initState();

    _sessionStartTime = DateTime.now();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _controller.scrollController.addListener(() {
      if (!_controller.scrollController.hasClients) return;

      final maxScroll = _controller.scrollController.position.maxScrollExtent;
      final currScroll = _controller.scrollController.offset;

      final shouldShow = (maxScroll - currScroll) > 100;
      if (shouldShow != _showScrollFAB) {
        setState(() => _showScrollFAB = shouldShow);
        logDebug('[Scroll FAB] Visibility changed: $_showScrollFAB');
      }
    });

    _initSession();
    _checkAndShowDisclaimer();
  }

  Future<void> _checkAndShowDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_chat_disclaimer') ?? false;

    if (!hasSeen) {
      if (!mounted) return;
      
      // Delay slightly to ensure context is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: isDark 
              ? MindurColors.darkSurfaceContainerHigh 
              : MindurColors.lightSurfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Beta Notice',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? MindurColors.darkTextPrimary : MindurColors.lightTextPrimary,
            ),
          ),
          content: Text(
            'Mind-ur is still in early development. AI replies might take a bit longer than usual as we optimize our models.\n\nThank you for your patience!',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? MindurColors.darkTextSecondary : MindurColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await prefs.setBool('has_seen_chat_disclaimer', true);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                'Understood',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MindurColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _initSession() async {
    logDebug('[InitSession] Creating a new session...');
    final newSessionId = await _controller.createNewSession();
    logDebug('[InitSession] New session created: $newSessionId');

    await _controller.loadSession(newSessionId);
    logDebug('[InitSession] Loaded session $newSessionId');

    await _controller.sendInitialGreeting();
    logDebug('[InitSession] Sent initial AI greeting');

    await AnalyticsService().logChatSessionStarted();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    logDebug('[SendMessage] User message length: ${text.length}');

    AnalyticsService().logChatMessageSent(messageLength: text.length);

    _controller.sendMessage(text);
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_sessionStartTime);
    final messageCount = _controller.messagesNotifier.value
        .where((m) => m.isUser)
        .length;

    AnalyticsService().logChatSessionEnded(
      duration: duration,
      messageCount: messageCount,
    );

    _controller.onSessionEnd();

    _controller.dispose();
    _inputController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        key: _scaffoldKey,

        endDrawer: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _controller.sessionsNotifier,
          builder: (context, sessions, _) {
            return SessionDrawer(
              sessions: sessions,
              onSessionTap: (sessionId) async {
                if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
                  context.pop();
                }
                await _controller.loadSession(sessionId);
              },
              onDeleteSession: (sessionId) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Session?'),
                    content: const Text(
                      'Are you sure you want to delete this chat session?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _controller.deleteSession(sessionId);

                  final updatedSessions = _controller.sessionsNotifier.value;
                  if (updatedSessions.isNotEmpty) {
                    await _controller.loadSession(
                      updatedSessions.first['id'] as String,
                    );
                  } else {
                    final newId = await _controller.createNewSession();
                    await _controller.loadSession(newId);
                    await _controller.sendInitialGreeting();
                  }
                }
              },
            );
          },
        ),

        appBar: AppBar(
          title: const Text('Aurora AI'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              tooltip: 'Session History',
            ),
          ],
        ),

        body: FadeTransition(
          opacity: _fadeController,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder<List<ChatMessage>>(
                    valueListenable: _controller.messagesNotifier,
                    builder: (context, messages, _) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet!',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _controller.scrollController,
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: MediaQuery.of(context).padding.bottom + 40,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return MessageBubble(
                            msg: msg,
                            onLongPress: () {},
                            avatar: msg.isUser
                                ? null
                                : const CircleAvatar(
                                    radius: 16,
                                    backgroundImage: AssetImage(
                                      'assets/images/ai.png',
                                    ),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 80,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _controller.isTypingNotifier,
                    builder: (context, isTyping, _) => InputBar(
                      controller: _inputController,
                      isTyping: isTyping,
                      onSend: _sendMessage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        floatingActionButton: _showScrollFAB
            ? FloatingActionButton(
                mini: true,
                backgroundColor: theme.colorScheme.primary,
                onPressed: _controller.scrollController.hasClients
                    ? () => _controller.scrollController.animateTo(
                        _controller.scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                    : null,
                child: const Icon(Icons.arrow_downward),
              )
            : null,
      ),
    );
  }
}
