  import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CwCalories extends StatelessWidget {
  final num totalCalories;
  final num usercalgoal;

  const CwCalories({
    super.key,
    required this.totalCalories,
    required this.usercalgoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool goalIsZero = usercalgoal == 0;

    final double percent =
        goalIsZero
            ? 0
            : (totalCalories / usercalgoal).clamp(0.0, 1.0).toDouble();

    final double rawPercent =
        goalIsZero ? 0 : (totalCalories / usercalgoal * 100);

    final bool isOver = rawPercent >= 100;
    final String percentText =
        isOver ? "OVER" : "${rawPercent.toStringAsFixed(1)}%";

    final num remaining =
        (usercalgoal - totalCalories) <= 0 ? 0 : (usercalgoal - totalCalories);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Semantics(
              label: 'Calories intake progress',
              value: percentText,
              child: CircularPercentIndicator(
                radius: 58.0,
                lineWidth: 24,
                percent: percent,
                progressColor:
                    isOver ? colorScheme.error : colorScheme.primary,
                backgroundColor:
                    colorScheme.onSurface.withOpacity(0.08),
                animation: true,
                animationDuration: 3000,
                circularStrokeCap: CircularStrokeCap.round,
                center: Text(
                  percentText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const Spacer(),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🏆 Base Goal \n$usercalgoal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '🔥 $remaining Calories\n',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: remaining == 0
                              ? Colors.green
                              : colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'Remaining',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}