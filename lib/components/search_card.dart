import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchCard extends StatelessWidget {
  final double witdh;
  final double height;
  final String title;
  final String description;
  final Function()? onPressed;

  const SearchCard({
    super.key,
    required this.witdh,
    required this.height,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorScheme.surface,
      ),
      width: witdh,
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: Icon(
            LucideIcons.plus,
            color: colorScheme.primary,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
