import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/models/user_profile.dart';
import 'package:mindur/theme/app_background.dart';
import 'package:mindur/utils/journal_streak_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindur/components/circular_elevated_button.dart';
import 'package:mindur/components/recent_entry_card.dart';
import 'package:mindur/data/sample_habit.dart';
import 'package:mindur/data/sample_journal.dart';
import 'package:mindur/data/sample_food_extended.dart';
import 'package:mindur/utils/pet_selection.dart';
import 'package:flutter_svg/svg.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../components/homescreen_cards.dart';
import '../constant/datetime.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int journalCurrentStreak = 0;
  int longestStreak = 0;

  final User? user = FirebaseAuth.instance.currentUser;
  double habitProgress = 0.0;

  List<Map<String, dynamic>> journalEntries = [];
  List<Map<String, dynamic>> habits = [];
  bool isLoading = true;

  UserProfile? userProfile;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _checkAchievements(); // 🆕 Check achievements on app open
  }

  /// 🆕 Check and send achievement notifications
  Future<void> _checkAchievements() async {
    await NotificationHelper.checkAchievements();
  }

  bool _isToday(dynamic timestamp) {
    if (timestamp == null) return false;
    DateTime lastDate;
    if (timestamp is Timestamp) {
      lastDate = timestamp.toDate();
    } else if (timestamp is String) {
      lastDate =
          DateTime.tryParse(timestamp) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      return false;
    }

    final now = DateTime.now();
    return lastDate.day == now.day &&
        lastDate.month == now.month &&
        lastDate.year == now.year;
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final profile = await FirestoreService().fetchUserProfile();

      final journalSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('journals')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      final habitSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      final streakData = await JournalStreakUtil.getJournalStreak(uid);

      final fetchedHabits = habitSnapshot.docs.map((doc) {
        final data = doc.data();
        final bool wasCompleted = data['isCompleted'] ?? false;
        final dynamic lastCompletedAt = data['lastCompletedAt'];

        final bool isCompletedToday = wasCompleted && _isToday(lastCompletedAt);

        return {...data, 'isCompleted': isCompletedToday};
      }).toList();

      int completedCount = fetchedHabits
          .where((h) => h['isCompleted'] == true)
          .length;
      int totalCount = fetchedHabits.length;

      double calculatedProgress = totalCount == 0
          ? 0.0
          : completedCount / totalCount;

      if (!mounted) return;

      final currentStreak = streakData['currentStreak'] ?? 0;

      setState(() {
        userProfile = profile;
        journalEntries = journalSnapshot.docs.map((doc) => doc.data()).toList();
        habits = fetchedHabits;
        habitProgress = calculatedProgress;
        journalCurrentStreak = currentStreak;
        longestStreak = streakData['longestStreak'] ?? 0;
        isLoading = false;
      });

      // ✅ LOG STREAK MILESTONE (only on significant milestones)
      if (currentStreak > 0 &&
          (currentStreak == 7 ||
              currentStreak == 14 ||
              currentStreak == 30 ||
              currentStreak == 60 ||
              currentStreak == 100)) {
        await AnalyticsService().logJournalStreakMilestone(
          streakDays: currentStreak,
        );
      }

      // ✅ UPDATE USER PROPERTIES
      await AnalyticsService().setUserProperties(
        journalStreak: currentStreak,
        habitStreak: completedCount,
      );

      // ✅ LOG DAILY HABITS SUMMARY (if user has habits)
      if (totalCount > 0) {
        await AnalyticsService().logDailyHabitsSummary(
          completed: completedCount,
          total: totalCount,
        );
      }
    } catch (e) {
      // ✅ LOG ERROR
      await AnalyticsService().logError(
        error: e.toString(),
        reason: 'Failed to fetch user data on home screen',
      );

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String formattedDateFromTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Unknown date";
    try {
      final dt = timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final String selectedPet = userProfile?.petSelection ?? "default_pet";
    final String petPath = PetSelection(pet: selectedPet).petPath;

    final source = habits.isNotEmpty ? habits : demoHabits;
    final limitedHabits = source.take(4).toList();

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularElevatedButton(
                onpressed: () {
                  context.pushNamed('account');
                },
                iconData: LucideIcons.user,
              ),
              Text(
                "MINDUR",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              CircularElevatedButton(
                onpressed: () {
                  context.pushNamed('notifications');
                },
                iconData: LucideIcons.bell,
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${GreetingUtil.getGreeting()} ${user?.displayName ?? "Anonymous"}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HomescreenCards(
                            height: MediaQuery.of(context).size.height * 0.13,
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Streak"),
                                Text(
                                  "🔥 $journalCurrentStreak Days",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          kIsWeb
                              ? const SizedBox.shrink()
                              : TransparentCard(
                                  height:
                                      MediaQuery.of(context).size.height * 0.19,
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  child: SvgPicture.asset(
                                    "assets/images/svg/$petPath",
                                    fit: BoxFit.cover,
                                    placeholderBuilder: (_) =>
                                        const Icon(Icons.pets),
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Recent Entries",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: journalEntries.isNotEmpty
                            ? ListView.builder(
                                itemCount: journalEntries.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final entry = journalEntries[index];
                                  return RecentEntryCard(
                                    text: entry['title'] ?? 'No Title',
                                    subtitle: formattedDateFromTimestamp(
                                      entry['timestamp'],
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: demoJournalEntries.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return RecentEntryCard(
                                    text: demoJournalEntries[index].title,
                                    subtitle: formattedDateFromTimestamp(
                                      demoJournalEntries[index].timestamp,
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "🔥 What Matters Today",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),

                            const SizedBox(height: 20),

                            CircularPercentIndicator(
                              radius: 78,
                              lineWidth: 22,
                              percent: habitProgress,
                              progressColor: colors.secondary,
                              backgroundColor: colors.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                              animation: true,
                              animationDuration: 3000,
                              circularStrokeCap: CircularStrokeCap.round,
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(habitProgress * 100).toStringAsFixed(0)}%",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${habits.where((h) => h['isCompleted'] == true).length}"
                                    " of ${habits.length} Habits",
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colors.onSurface.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: limitedHabits.length,
                              itemBuilder: (context, index) {
                                final habit = limitedHabits[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.onSurface.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            habit['title'] ?? 'No Title',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: colors.onSurface,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.onSurface.withValues(
                                              alpha: 0.06,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            habit['priority'] ?? "NA",
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colors.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                     kDebugMode ? ElevatedButton(
                        onPressed: () async {
                          debugPrint("UPLOAD BUTTON PRESSED");
                          await removeDuplicateFoods();
                        },
                        child: const Icon(Icons.fastfood),
                      )
                      : const SizedBox.shrink(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
