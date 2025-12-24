import 'package:flutter/material.dart';

class RecentEntryCard extends StatelessWidget {
  final String text;
  final String subtitle;
  final double? height;
  final double? width;
  final TextStyle? textStyle;
  final Function()? onDelete;

  const RecentEntryCard({
    super.key,
    required this.text,
    required this.subtitle,
    this.height,
    this.width,
    this.textStyle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: 2,

        // 🔥 CHANGED: surface → surfaceContainerHigh
        color: colorScheme.surfaceContainerHigh,

        child: ListTile(
          title: Text(
            text,
            style:
                textStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.labelMedium,
            maxLines: 5,
          ),
          trailing: onDelete != null
              ? IconButton(
                  icon: Icon(
                    Icons.delete,

                    // already correct, kept as-is
                    color: colorScheme.error,
                  ),
                  onPressed: onDelete,
                )
              : null,
        ),
      ),
    );
  }
}
