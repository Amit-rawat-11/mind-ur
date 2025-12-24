import 'package:flutter/material.dart';

class SmoothInfiniteLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color; // now optional & theme-aware

  const SmoothInfiniteLoader({
    super.key,
    this.size = 40,
    this.strokeWidth = 4,
    this.color,
  });

  @override
  State<SmoothInfiniteLoader> createState() => _SmoothInfiniteLoaderState();
}

class _SmoothInfiniteLoaderState extends State<SmoothInfiniteLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final paintColor =
        widget.color ?? colorScheme.primary; // 🔥 theme default

    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 6.28, // 2π
            child: child,
          );
        },
        child: CustomPaint(
          painter: _SpinnerPainter(
            strokeWidth: widget.strokeWidth,
            color: paintColor,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;

  _SpinnerPainter({
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Rect rect = Offset.zero & size;
    const double startAngle = 0.0;
    const double sweepAngle = 2.4; // ~40% arc

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
