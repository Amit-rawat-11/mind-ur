import 'package:flutter/material.dart';

class CircularElevatedButton extends StatelessWidget {
  final VoidCallback? onpressed;
  final IconData iconData;

  const CircularElevatedButton({
    super.key,
    required this.onpressed,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 45,
      width: 45,
      child: ElevatedButton(
        onPressed: onpressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          padding: EdgeInsets.zero, // keep exact internal spacing
        ),
        child: Center(
          child: Icon(
            iconData,
            size: 24.0,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
