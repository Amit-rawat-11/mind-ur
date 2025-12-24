import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(delay: 0.0),
            SizedBox(width: 4),
            _Dot(delay: 0.2),
            SizedBox(width: 4),
            _Dot(delay: 0.4),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final double delay;
  const _Dot({this.delay = 0.0});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(
      Duration(milliseconds: (widget.delay * 1000).toInt()),
      () {
        if (mounted) _controller.repeat(reverse: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _animation,
      child: CircleAvatar(
        radius: 4.5,
        backgroundColor: colorScheme.onSurface,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
