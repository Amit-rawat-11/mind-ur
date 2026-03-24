import 'package:flutter/material.dart';

import '../models/habit.dart';
import 'input_textfield.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitdescController = TextEditingController();
  String priority = 'Medium';
  bool _isSubmitted = false;

  @override
  void dispose() {
    _habitNameController.dispose();
    _habitdescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        "Add New Habit",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 3.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputTextfield(
              labelText: 'Habit Name',
              controller: _habitNameController,
              isPassword: false,
            ),

            const SizedBox(height: 16),

            InputTextfield(
              labelText: 'Habit Description',
              controller: _habitdescController,
              isPassword: false,
            ),

            const SizedBox(height: 18),

            Text(
              "Priority",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'High',
                    groupValue: priority,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      setState(() => priority = value!);
                    },
                  ),
                  Text(
                    'High',
                    style: theme.textTheme.bodyMedium,
                  ),

                  Radio<String>(
                    value: 'Medium',
                    groupValue: priority,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      setState(() => priority = value!);
                    },
                  ),
                  Text(
                    'Medium',
                    style: theme.textTheme.bodyMedium,
                  ),

                  Radio<String>(
                    value: 'Low',
                    groupValue: priority,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      setState(() => priority = value!);
                    },
                  ),
                  Text(
                    'Low',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: theme.textTheme.labelMedium,
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitted
              ? null
              : () {
                  final habitName = _habitNameController.text.trim();
                  final habitdesc = _habitdescController.text.trim();

                  if (habitName.isEmpty) return;
                  
                  setState(() {
                    _isSubmitted = true;
                  });

                  final newHabit = Habit(
                    title: habitName,
                    description: habitdesc.isEmpty
                        ? "No description yet"
                        : habitdesc,
                    progress: 0.0,
                    priority: priority,
                    isCompleted: false,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 30)),
                    lastUpdated: DateTime.now(),
                    completedDates: const [],
                  );

                  _habitNameController.clear();
                  _habitdescController.clear();
                  Navigator.pop(context, newHabit);
                },
          child: _isSubmitted
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Add"),
        ),
      ],
    );
  }
}
