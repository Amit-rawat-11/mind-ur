import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;

  // Notification IDs
  static const int journalReminderMorning = 100;
  static const int journalReminderEvening = 101;
  static const int journalReminderNight = 102;
  
  static const int habitCheckMorning = 200;
  static const int habitCheckNoon = 201;
  static const int habitCheckEvening = 202;
  static const int habitCheckNight = 203;
  
  static const int streakReminder = 300;
  static const int streakWarning = 301;
  
  static const int weeklyReview = 400;
  static const int motivationalQuote = 401;
  static const int midWeekCheckIn = 402;
  static const int weekendReflection = 403;
  
  // 🆕 NEW: Achievement & Summary IDs
  static const int achievementBadge = 500;
  static const int dailySummary = 501;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Notification initialization error: $e');
    }
  }

  /// 🆕 FEATURE 9: Track notification opens
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _trackNotificationOpen(response.id ?? 0, response.payload ?? 'unknown');
  }

  /// 🆕 FEATURE 9: Analytics - Track notification opens
  Future<void> _trackNotificationOpen(int notificationId, String type) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .add({
        'notificationId': notificationId,
        'type': type,
        'openedAt': FieldValue.serverTimestamp(),
        'device': 'mobile',
      });
      debugPrint('📊 Analytics: Notification $notificationId opened');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    Importance importance = Importance.high,
  }) async {
    // 🆕 FEATURE 3: Proper notification channels
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'mindur_channel',
      channelName ?? 'Mind-ur Notifications',
      channelDescription: 'Notifications for journal reminders and habits',
      importance: importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: _getGroupKey(id),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// 🆕 FEATURE 3: Get notification group key
  String _getGroupKey(int notificationId) {
    if (notificationId >= 200 && notificationId <= 203) {
      return 'habit_checkins';
    } else if (notificationId >= 100 && notificationId <= 102) {
      return 'journal_reminders';
    } else if (notificationId >= 400 && notificationId <= 403) {
      return 'engagement';
    } else if (notificationId >= 500 && notificationId <= 501) {
      return 'achievements';
    }
    return 'general';
  }

  /// 🆕 FEATURE 2: Get smart scheduled time based on user behavior
  Future<int> _getSmartHour(String timeSlot, int defaultHour) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return defaultHour;

    try {
      // Check if we have enough data (at least 7 days)
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      
      final analytics = await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .where('openedAt', isGreaterThan: twoWeeksAgo)
          .where('type', isEqualTo: timeSlot)
          .get();

      if (analytics.docs.length < 5) {
        return defaultHour; // Not enough data yet
      }

      // Calculate most common hour user opens notifications
      final hourCounts = <int, int>{};
      for (final doc in analytics.docs) {
        final timestamp = doc['openedAt'] as Timestamp?;
        if (timestamp != null) {
          final hour = timestamp.toDate().hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        }
      }

      if (hourCounts.isEmpty) return defaultHour;

      // Find most active hour
      final mostActiveHour = hourCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      debugPrint('📊 Smart scheduling: $timeSlot shifted from $defaultHour to $mostActiveHour');
      return mostActiveHour;
    } catch (e) {
      debugPrint('Smart scheduling error: $e');
      return defaultHour;
    }
  }

  /// Schedule daily journal reminder
  Future<void> scheduleJournalReminder(String timing) async {
    await cancelJournalReminders();

    int hour, minute, notificationId;

    switch (timing.toLowerCase()) {
      case 'morning':
        hour = await _getSmartHour('journal_morning', 8);
        minute = 0;
        notificationId = journalReminderMorning;
        break;
      case 'evening':
        hour = await _getSmartHour('journal_evening', 18);
        minute = 0;
        notificationId = journalReminderEvening;
        break;
      case 'nightly':
        hour = await _getSmartHour('journal_nightly', 21);
        minute = 0;
        notificationId = journalReminderNight;
        break;
      default:
        return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'journal_reminder',
      'Journal Reminders',
      channelDescription: 'Daily reminders to write in your journal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'journal_reminders',
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '📝 Time to reflect',
      'Take a moment to write in your journal',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'journal_$timing',
    );

    debugPrint('✅ Journal reminder scheduled for $hour:$minute');
  }

  /// 🆕 FEATURE 6: Get contextual message based on day
  String _getContextualMessage(String baseType, int hour) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    // Monday motivation
    if (dayOfWeek == DateTime.monday && hour < 12) {
      return 'Happy Monday! Fresh start, fresh goals 🌟';
    }
    
    // Wednesday mid-week
    if (dayOfWeek == DateTime.wednesday) {
      return 'Hump day! You\'re halfway through the week 💪';
    }
    
    // Friday celebration
    if (dayOfWeek == DateTime.friday && hour > 17) {
      return 'TGIF! Finish strong before the weekend 🎉';
    }
    
    // Weekend vibes
    if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      return 'Weekend mode: perfect time for self-care 🌸';
    }

    // Default messages by type
    switch (baseType) {
      case 'morning':
        return 'Ready to conquer your habits today? Let\'s start strong!';
      case 'noon':
        return 'How are your habits going? Keep up the momentum!';
      case 'evening':
        return 'Almost done! Finish those last habits before dinner.';
      default:
        return 'Keep pushing forward! You\'ve got this!';
    }
  }

  /// Schedule all 4 habit check-in notifications
  Future<void> scheduleHabitCheckIns() async {
    await cancelHabitCheckIns();

    // 🆕 FEATURE 2: Smart scheduling
    final morningHour = await _getSmartHour('habit_morning', 7);
    final noonHour = await _getSmartHour('habit_noon', 12);
    final eveningHour = await _getSmartHour('habit_evening', 18);
    final nightHour = await _getSmartHour('habit_night', 21);

    // Morning check-in
    await _scheduleHabitCheckIn(
      notificationId: habitCheckMorning,
      hour: morningHour,
      minute: 0,
      title: '🌅 Good Morning!',
      body: _getContextualMessage('morning', morningHour),
      payload: 'habit_morning',
    );

    // Noon check-in
    await _scheduleHabitCheckIn(
      notificationId: habitCheckNoon,
      hour: noonHour,
      minute: 0,
      title: '☀️ Midday Check-in',
      body: _getContextualMessage('noon', noonHour),
      payload: 'habit_noon',
    );

    // Evening check-in
    await _scheduleHabitCheckIn(
      notificationId: habitCheckEvening,
      hour: eveningHour,
      minute: 0,
      title: '🌆 Evening Reminder',
      body: _getContextualMessage('evening', eveningHour),
      payload: 'habit_evening',
    );

    // Night check-in
    await _scheduleHabitCheckIn(
      notificationId: habitCheckNight,
      hour: nightHour,
      minute: 0,
      title: '🌙 Goodnight Check',
      body: 'Time to wind down. Did you complete your habits today?',
      payload: 'habit_night',
    );

    debugPrint('✅ All 4 habit check-ins scheduled (smart times)');
  }

  Future<void> _scheduleHabitCheckIn({
    required int notificationId,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 🆕 FEATURE 3: Grouped notifications
    const androidDetails = AndroidNotificationDetails(
      'habit_checkins',
      'Habit Check-ins',
      channelDescription: 'Regular reminders to check and complete your habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'habit_checkins',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Send personalized habit completion notification
  Future<void> sendHabitCompletionNotification({
    required bool allCompleted,
    required int completedCount,
    required int totalCount,
  }) async {
    String title;
    String body;

    if (allCompleted && totalCount > 0) {
      final messages = [
        '🎉 All habits completed! You\'re on fire today!',
        '⭐ Perfect day! All $totalCount habits done!',
        '🏆 Champion! You crushed all your habits today!',
        '💪 Unstoppable! All habits completed!',
        '🌟 Flawless victory! All habits checked off!',
      ];
      title = '✅ Amazing Work!';
      body = messages[Random().nextInt(messages.length)];
    } else if (completedCount > 0) {
      final remaining = totalCount - completedCount;
      title = '💪 Keep Going!';
      body = '$completedCount/$totalCount habits done! Only $remaining more to go!';
    } else if (totalCount > 0) {
      final messages = [
        'Your future self will thank you! Start your first habit now.',
        'Every journey starts with a single step. Begin today!',
        'You\'ve got this! Just one habit to get started.',
        'Small progress is still progress. Start now!',
        'The best time to start was yesterday. The second best time is now!',
      ];
      title = '🎯 Let\'s Begin!';
      body = messages[Random().nextInt(messages.length)];
    } else {
      return;
    }

    await showNotification(
      id: habitCheckNight,
      title: title,
      body: body,
      payload: 'habit_completion',
      channelId: 'habit_checkins',
      channelName: 'Habit Check-ins',
    );
  }

  /// Check and send streak warning if no journal entry today
  Future<void> checkAndSendStreakWarning() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .where('timestamp', isGreaterThanOrEqualTo: today)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        await showNotification(
          id: streakWarning,
          title: '⚠️ Your Streak is at Risk!',
          body: 'Don\'t break your streak! Write a quick journal entry before midnight.',
          payload: 'streak_warning',
          channelId: 'streak_protection',
          channelName: 'Streak Protection',
          importance: Importance.max,
        );
        debugPrint('⚠️ Streak warning sent');
      }
    } catch (e) {
      debugPrint('Error checking streak: $e');
    }
  }

  /// Schedule streak warning check (8 PM daily)
  Future<void> scheduleStreakWarningCheck() async {
    final smartHour = await _getSmartHour('streak_warning', 20);
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      smartHour,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'streak_warning',
      'Streak Warnings',
      channelDescription: 'Alerts when your journal streak is at risk',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      streakWarning,
      '⚠️ Your Streak is at Risk!',
      'Don\'t break your streak! Write a quick journal entry before midnight.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak_warning',
    );

    debugPrint('✅ Streak warning scheduled for $smartHour PM daily');
  }

  /// Schedule streak milestone notification
  Future<void> scheduleStreakMilestone(int streakDays) async {
    if (streakDays % 7 == 0 && streakDays > 0) {
      await showNotification(
        id: streakReminder,
        title: '🔥 Amazing streak!',
        body: 'You\'ve maintained a $streakDays day journal streak! Keep it up!',
        payload: 'streak_milestone',
        channelId: 'achievements',
        channelName: 'Achievements',
      );
    }
  }

  /// 🆕 FEATURE 4: Achievement Badges System
  Future<void> checkAndSendAchievementBadges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get user stats
      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data();
      
      final journalCount = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .count()
          .get();
      
      final totalJournals = journalCount.count ?? 0;
      
      // Check various achievement milestones
      await _checkJournalMilestone(totalJournals);
      await _checkStreakMilestone(uid);
      await _checkHabitMilestone(uid);
      await _checkPerfectWeek(uid);
      
    } catch (e) {
      debugPrint('Achievement check error: $e');
    }
  }

  Future<void> _checkJournalMilestone(int count) async {
    final milestones = [10, 30, 50, 100, 365];
    
    if (milestones.contains(count)) {
      String badge;
      String message;
      
      switch (count) {
        case 10:
          badge = '🌱';
          message = 'First 10 entries! Your journey begins!';
          break;
        case 30:
          badge = '🌿';
          message = '30 journal entries! Building momentum!';
          break;
        case 50:
          badge = '🌳';
          message = '50 entries! You\'re a journaling pro!';
          break;
        case 100:
          badge = '🏆';
          message = '100 ENTRIES! Legendary dedication!';
          break;
        case 365:
          badge = '💎';
          message = 'ONE YEAR! You\'re a journaling master!';
          break;
        default:
          return;
      }
      
      await showNotification(
        id: achievementBadge,
        title: '$badge Achievement Unlocked!',
        body: message,
        payload: 'achievement_journal_$count',
        channelId: 'achievements',
        channelName: 'Achievements',
      );
      
      // Save badge to Firestore
      await _saveBadge('journal_$count', badge, message);
    }
  }

  Future<void> _checkStreakMilestone(String uid) async {
    // This is called from home_screen already
  }

  Future<void> _checkHabitMilestone(String uid) async {
    try {
      final habitsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();
      
      int totalCompletions = 0;
      for (final doc in habitsSnapshot.docs) {
        final completedDates = doc['completedDates'] as List?;
        totalCompletions += completedDates?.length ?? 0;
      }
      
      final milestones = [50, 100, 250, 500, 1000];
      if (milestones.contains(totalCompletions)) {
        await showNotification(
          id: achievementBadge + 1,
          title: '⚡ Habit Master!',
          body: 'You\'ve completed $totalCompletions habits total! Incredible!',
          payload: 'achievement_habit_$totalCompletions',
          channelId: 'achievements',
          channelName: 'Achievements',
        );
        
        await _saveBadge('habit_$totalCompletions', '⚡', 'Habit Master');
      }
    } catch (e) {
      debugPrint('Habit milestone error: $e');
    }
  }

  Future<void> _checkPerfectWeek(String uid) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: 7));
      
      final journalDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .where('timestamp', isGreaterThan: weekStart)
          .get();
      
      // Check if journaled every day for 7 days
      final uniqueDays = <String>{};
      for (final doc in journalDocs.docs) {
        final timestamp = (doc['timestamp'] as Timestamp).toDate();
        uniqueDays.add('${timestamp.year}-${timestamp.month}-${timestamp.day}');
      }
      
      if (uniqueDays.length >= 7) {
        await showNotification(
          id: achievementBadge + 2,
          title: '🌟 Perfect Week!',
          body: 'You journaled every day this week! Outstanding!',
          payload: 'achievement_perfect_week',
          channelId: 'achievements',
          channelName: 'Achievements',
        );
        
        await _saveBadge('perfect_week_${now.millisecondsSinceEpoch}', '🌟', 'Perfect Week');
      }
    } catch (e) {
      debugPrint('Perfect week check error: $e');
    }
  }

  Future<void> _saveBadge(String badgeId, String emoji, String title) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('badges')
          .doc(badgeId)
          .set({
        'emoji': emoji,
        'title': title,
        'earnedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🏆 Badge saved: $badgeId');
    } catch (e) {
      debugPrint('Badge save error: $e');
    }
  }

  /// 🆕 FEATURE 8: Daily Completion Summary
  Future<void> sendDailySummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get today's journal count
      final journalCount = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .where('timestamp', isGreaterThanOrEqualTo: today)
          .count()
          .get();

      // Get today's habit completion
      final habitsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      int totalHabits = habitsSnapshot.docs.length;
      int completedHabits = 0;

      for (final doc in habitsSnapshot.docs) {
        final data = doc.data();
        final lastCompletedAt = data['lastCompletedAt'];
        final isCompleted = data['isCompleted'] ?? false;

        if (isCompleted && lastCompletedAt != null) {
          final completedDate = (lastCompletedAt as Timestamp).toDate();
          final completedToday = DateTime(
            completedDate.year,
            completedDate.month,
            completedDate.day,
          );

          if (completedToday == today) {
            completedHabits++;
          }
        }
      }

      // Get current streak
      final streakDoc = await _db.collection('users').doc(uid).get();
      final streakData = streakDoc.data()?['journalStreak'] as Map?;
      final currentStreak = streakData?['currentStreak'] ?? 0;

      // Build summary message
      final journalEmoji = journalCount.count! > 0 ? '✓' : '✗';
      final habitPercent = totalHabits > 0 
          ? ((completedHabits / totalHabits) * 100).toStringAsFixed(0)
          : '0';

      String summaryText = 'Today:\n'
          '$journalEmoji ${journalCount.count} journal ${journalCount.count == 1 ? 'entry' : 'entries'}\n'
          '💪 $completedHabits/$totalHabits habits ($habitPercent%)\n'
          '🔥 $currentStreak day streak';

      String title = completedHabits == totalHabits && journalCount.count! > 0
          ? '🌟 Perfect Day!'
          : '📊 Today\'s Summary';

      await showNotification(
        id: dailySummary,
        title: title,
        body: summaryText,
        payload: 'daily_summary',
        channelId: 'summary',
        channelName: 'Daily Summaries',
      );

      debugPrint('📊 Daily summary sent');
    } catch (e) {
      debugPrint('Daily summary error: $e');
    }
  }

  /// Schedule daily summary (10:30 PM)
  Future<void> scheduleDailySummary() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22, // 10 PM
      30,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'summary',
      'Daily Summaries',
      channelDescription: 'End of day progress summaries',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'achievements',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      dailySummary,
      '📊 Today\'s Summary',
      'See how you did today',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_summary',
    );

    debugPrint('✅ Daily summary scheduled for 10:30 PM');
  }

  /// Schedule weekly review (Sunday 7 PM)
  Future<void> scheduleWeeklyReview() async {
    final now = tz.TZDateTime.now(tz.local);
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      19,
      0,
    );

    while (scheduledDate.weekday != DateTime.sunday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'weekly_review',
      'Weekly Reviews',
      channelDescription: 'Weekly progress summaries',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'engagement',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      weeklyReview,
      '📊 Your Weekly Review',
      'Take a moment to reflect on this week. What went well? What can improve?',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_review',
    );

    debugPrint('✅ Weekly review scheduled for Sundays at 7 PM');
  }

  /// Schedule motivational quote
  Future<void> scheduleMotivationalQuote() async {
    final quotes = [
      'The only way to do great work is to love what you do. - Steve Jobs',
      'Believe you can and you\'re halfway there. - Theodore Roosevelt',
      'Success is not final, failure is not fatal. - Winston Churchill',
      'Your limitation—it\'s only your imagination.',
      'Great things never come from comfort zones.',
      'Dream it. Wish it. Do it.',
      'Success doesn\'t just find you. You have to go out and get it.',
      'The harder you work for something, the greater you\'ll feel when you achieve it.',
      'Don\'t stop when you\'re tired. Stop when you\'re done.',
      'Wake up with determination. Go to bed with satisfaction.',
    ];

    final now = tz.TZDateTime.now(tz.local);
    final random = Random();
    
    final randomHour = 10 + random.nextInt(7);
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      randomHour,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'motivation',
      'Motivational Quotes',
      channelDescription: 'Daily inspiration to keep you motivated',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      groupKey: 'engagement',
    );

    const details = NotificationDetails(android: androidDetails);

    final selectedQuote = quotes[random.nextInt(quotes.length)];

    await _notifications.zonedSchedule(
      motivationalQuote,
      '💭 Daily Inspiration',
      selectedQuote,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'motivational_quote',
    );

    debugPrint('✅ Motivational quote scheduled');
  }

  /// Schedule mid-week check-in
  Future<void> scheduleMidWeekCheckIn() async {
    final now = tz.TZDateTime.now(tz.local);
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      12,
      0,
    );

    while (scheduledDate.weekday != DateTime.wednesday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'midweek_checkin',
      'Mid-week Check-ins',
      channelDescription: 'Wednesday wellness check-ins',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'engagement',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      midWeekCheckIn,
      '🎯 Mid-Week Check-in',
      'You\'re halfway through the week! How are you feeling? Take a moment to journal.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'midweek_checkin',
    );

    debugPrint('✅ Mid-week check-in scheduled for Wednesdays at 12 PM');
  }

  /// Schedule weekend reflection
  Future<void> scheduleWeekendReflection() async {
    final now = tz.TZDateTime.now(tz.local);
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );

    while (scheduledDate.weekday != DateTime.saturday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'weekend_reflection',
      'Weekend Reflections',
      channelDescription: 'Saturday morning reflections',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'engagement',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      weekendReflection,
      '🌈 Weekend Reflection',
      'It\'s the weekend! Take time to relax and reflect on your journey.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekend_reflection',
    );

    debugPrint('✅ Weekend reflection scheduled for Saturdays at 10 AM');
  }

  /// Schedule all app notifications
  Future<void> scheduleAllNotifications(String journalTiming) async {
    debugPrint('📅 Scheduling all notifications with smart features...');
    
    await scheduleJournalReminder(journalTiming);
    await scheduleHabitCheckIns();
    await scheduleStreakWarningCheck();
    await scheduleWeeklyReview();
    await scheduleMotivationalQuote();
    await scheduleMidWeekCheckIn();
    await scheduleWeekendReflection();
    await scheduleDailySummary(); // 🆕
    
    debugPrint('✅ All notifications scheduled with smart scheduling!');
  }

  // Cancellation methods
  Future<void> cancelJournalReminders() async {
    await _notifications.cancel(journalReminderMorning);
    await _notifications.cancel(journalReminderEvening);
    await _notifications.cancel(journalReminderNight);
  }

  Future<void> cancelHabitCheckIns() async {
    await _notifications.cancel(habitCheckMorning);
    await _notifications.cancel(habitCheckNoon);
    await _notifications.cancel(habitCheckEvening);
    await _notifications.cancel(habitCheckNight);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'Your notifications are working perfectly!',
      payload: 'test',
    );
  }
}