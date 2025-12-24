// lib/components/chat_screen_widgets/input_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping; // kept (not removed)
  final bool isSending;
  final VoidCallback onSend;

  const InputBar({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disabled = isSending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  final isEnter =
                      event.logicalKey == LogicalKeyboardKey.enter;
                  final isShift =
                      HardwareKeyboard.instance.isShiftPressed;

                  if (isEnter && !isShift && !disabled) {
                    onSend();
                  }
                }
              },
              child: TextField(
                controller: controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) {
                  if (!disabled) onSend();
                },
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: disabled ? null : onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: disabled
                    ? colorScheme.onSurface.withOpacity(0.35)
                    : colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
