import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PersonalizedSelectionGroup<T> extends StatelessWidget {
  final String question;
  final List<SelectionOption<T>> options;
  final T? groupValue;
  final ValueChanged<T?> onChanged;

  const PersonalizedSelectionGroup({
    super.key,
    required this.question,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white.withAlpha(220),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((option) {
          final isSelected = groupValue == option.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(16),
              splashColor: MindurColors.sageMint.withAlpha(30),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? MindurColors.sageMint.withAlpha(25) 
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? MindurColors.sageMint.withAlpha(150)
                        : Colors.white.withAlpha(15),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MindurColors.sageMint.withAlpha(30),
                          blurRadius: 12,
                          spreadRadius: 0,
                        )
                      ]
                    : [],
                ),
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Icon(
                        option.icon, 
                        color: isSelected ? MindurColors.sageMint : Colors.white.withAlpha(120),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white.withAlpha(180),
                            ),
                          ),
                          if (option.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              option.subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected 
                                  ? Colors.white.withAlpha(160) 
                                  : Colors.white.withAlpha(100),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    
                    // Custom animated radio circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? MindurColors.sageMint : Colors.white.withAlpha(60),
                          width: isSelected ? 6 : 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SelectionOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}
