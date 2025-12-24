import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback? onLongPress;
  final Widget? avatar;

  const MessageBubble({
    super.key,
    required this.msg,
    this.onLongPress,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = msg.isUser;

    // ✅ THINKING BUBBLE
    if (msg.isThinking) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (avatar != null) avatar!,
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: const _ThinkingDots(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ NORMAL MESSAGE
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && avatar != null) avatar!,

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: GestureDetector(
                      onLongPress: onLongPress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? colorScheme.primary.withOpacity(0.9)
                              : colorScheme.surface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _dots;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dots = IntTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dots,
      builder: (_, __) {
        return Text(
          "Aurora is thinking${'.' * _dots.value}",
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}
