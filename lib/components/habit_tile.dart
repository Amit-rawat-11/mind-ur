import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/firebase_service.dart';

class HabitTile extends StatelessWidget {
  final String habitId;
  final String habitName;
  final bool habitCompleted;
  final Function(bool?)? onChanged;
  final double? habitProgress;
  final String habitPriority;
  final Function deletehabit;

  const HabitTile({
    super.key,
    required this.habitId,
    required this.habitName,
    required this.habitCompleted,
    required this.habitPriority,
    this.habitProgress,
    required this.onChanged,
    required this.deletehabit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    title: Text(
                      'Confirm Delete',
                      style: theme.textTheme.titleMedium,
                    ),
                    content: Text(
                      'Are you sure you want to delete "$habitName"?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "$habitName"')),
                  );
                  FirestoreService().deleteHabit(habitId);
                  deletehabit(habitId);
                }
              },
              backgroundColor: colorScheme.error,
              borderRadius: BorderRadius.circular(12),
              foregroundColor: Colors.white,
              icon: LucideIcons.trash2,
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),

          child: Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: habitCompleted,
                  onChanged: onChanged,
                  activeColor: colorScheme.primary,
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Text(
                  habitName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width: 65,
                height: 40,
                child: Chip(
                  label: Text(
                    habitPriority,
                    style: theme.textTheme.labelMedium,
                  ),
                  backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
