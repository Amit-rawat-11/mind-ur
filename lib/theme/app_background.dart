import 'package:flutter/material.dart';
import 'colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? MindurColors.darkBackgroundGradient
            : MindurColors.lightBackgroundGradient,
      ),
      child: child,
    );
  }
}
