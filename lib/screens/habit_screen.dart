import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:mindur/models/habit.dart';

import '../components/add_habit_dialog.dart';
import '../components/habit_tile.dart';
import '../constant/datetime.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Habit> habits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => isLoading = true);
    final fetchedHabits = await _firestoreService.fetchHabits();
    setState(() {
      habits = fetchedHabits;
      isLoading = false;
    });
  }

  void deletehabiit(String habitId) async {
    // Find the habit to get its data before deleting
    final habitToDelete = habits.firstWhere((h) => h.id == habitId);

    // Calculate days active
    final daysActive = DateTime.now()
        .difference(habitToDelete.startDate)
        .inDays;

    await _firestoreService.deleteHabit(habitId);

    // ✅ LOG HABIT DELETION
    await AnalyticsService().logHabitDeleted(daysActive: daysActive);

    setState(() {
      habits.removeWhere((habit) => habit.id == habitId);
    });
  }

  Map<DateTime, int> generateHeatmapData() {
    Map<DateTime, int> heatmap = {};
    for (var habit in habits) {
      for (var date in habit.completedDates) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        heatmap.update(normalizedDate, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return heatmap;
  }

  /// ✅ FIXED: now also updates `lastCompletedAt`
  void checkboxChanged(bool? value, int index) async {
    if (value == null) return;

    final habit = habits[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      habit.isCompleted = value;

      if (value) {
        if (!habit.completedDates.any(
          (d) =>
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day,
        )) {
          habit.completedDates.add(today);
        }

        habit.lastCompletedAt = now;
      } else {
        habit.completedDates.removeWhere(
          (d) =>
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day,
        );
      }

      habit.lastUpdated = now;
    });

    if (habit.id != null) {
      await _firestoreService.updateHabit(habit.id!, habit);
    }

    // ✅ LOG HABIT COMPLETION
    if (value) {
      final streakDays = habit.completedDates.length;
      await AnalyticsService().logHabitCompleted(
        habitName: habit.title,
        streakDays: streakDays,
      );
    }
  }

  void _showAddHabitDialog() async {
    final result = await showDialog<Habit>(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );

    if (result != null) {
      await _firestoreService.addHabits(result);

      // ✅ LOG HABIT CREATION
      await AnalyticsService().logHabitCreated(
        priority: result.priority,
        habitName: result.title,
      );

      _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final heatmapData = generateHeatmapData();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(TimeUtils.formattedDate),
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHabitDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 70),
                children: [
                  HeatMapCalendar(
                    datasets: heatmapData,
                    fontSize: 14,
                    size: MediaQuery.of(context).size.height * 0.047,
                    colorMode: ColorMode.color,
                    monthFontSize: 14,
                    showColorTip: false,
                    weekTextColor: colors.onSurface.withOpacity(0.5),
                    colorsets: {
                      1: colors.secondary.withOpacity(0.50),
                      2: colors.secondary.withOpacity(0.60),
                      3: colors.secondary.withOpacity(0.70),
                      4: colors.secondary.withOpacity(0.85),
                      5: colors.secondary.withOpacity(0.95),
                      6: colors.secondary,
                    },
                  ),
                  if (habits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "You have no habits yet.\nSwipe to remove. Tap + to add.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];

                        final isCompletedToday = habit.completedDates.any(
                          (d) =>
                              d.year == todayNormalized.year &&
                              d.month == todayNormalized.month &&
                              d.day == todayNormalized.day,
                        );

                        return HabitTile(
                          habitName: habit.title,
                          habitCompleted: isCompletedToday,
                          onChanged: (value) => checkboxChanged(value, index),
                          habitPriority: habit.priority,
                          habitId: habit.id!,
                          deletehabit: deletehabiit,
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}
