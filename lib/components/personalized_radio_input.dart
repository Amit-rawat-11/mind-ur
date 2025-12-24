// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class PerosnalizedRadioInput extends StatelessWidget {
  final String selectedValue;
  final String question;
  final String groupValue;
  final Function(Object?) onChanged;
  final String selectedValueb;
  final String selectedValuec;

  const PerosnalizedRadioInput({
    super.key,
    required this.selectedValue,
    required this.question,
    required this.groupValue,
    required this.selectedValueb,
    required this.selectedValuec,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              question,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            RadioListTile<String>(
              title: Text(
                selectedValue,
                style: theme.textTheme.bodyMedium,
              ),
              value: selectedValue,
              groupValue: groupValue,
              onChanged: onChanged,
              overlayColor:
                  WidgetStateProperty.all(colorScheme.primary),
              fillColor:
                  WidgetStateProperty.all(colorScheme.primary),
            ),

            RadioListTile<String>(
              title: Text(
                selectedValueb,
                style: theme.textTheme.bodyMedium,
              ),
              value: selectedValueb,
              groupValue: groupValue,
              onChanged: onChanged,
              overlayColor:
                  WidgetStateProperty.all(colorScheme.primary),
              fillColor:
                  WidgetStateProperty.all(colorScheme.primary),
            ),

            RadioListTile<String>(
              title: Text(
                selectedValuec,
                style: theme.textTheme.bodyMedium,
              ),
              value: selectedValuec,
              groupValue: groupValue,
              onChanged: onChanged,
              overlayColor:
                  WidgetStateProperty.all(colorScheme.primary),
              fillColor:
                  WidgetStateProperty.all(colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
