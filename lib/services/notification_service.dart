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

  // ==================== NOTIFICATION IDS ====================
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
  
  static const int achievementBadge = 500;
  static const int dailySummary = 501;

  // ==================== INITIALIZATION ====================
  
  /// 🆕 CRITICAL FIX: Initialize with proper channels
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      // 🆕 Create all notification channels FIRST
      await _createNotificationChannels();

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
      if (kDebugMode) {
        debugPrint('✅ NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Notification initialization error: $e');
      }
    }
  }

  /// 🆕 CRITICAL: Create all notification channels at startup
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Channel 1: Journal Reminders
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'journal_reminder',
        'Journal Reminders',
        description: 'Daily reminders to write in your journal',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Channel 2: Habit Check-ins
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'habit_checkins',
        'Habit Check-ins',
        description: 'Regular reminders to check and complete your habits',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Channel 3: Streak Protection
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'streak_protection',
        'Streak Protection',
        description: 'Alerts when your journal streak is at risk',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Channel 4: Achievements
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'achievements',
        'Achievements',
        description: 'Achievement badges and milestones',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Channel 5: Engagement
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'engagement',
        'Weekly Reviews & Motivation',
        description: 'Weekly reviews and motivational content',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
        showBadge: true,
      ),
    );

    // Channel 6: Daily Summary
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'summary',
        'Daily Summaries',
        description: 'End of day progress summaries',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    if (kDebugMode) {
      debugPrint('✅ All notification channels created');
    }
  }

  // ==================== PERMISSIONS ====================
  
  /// 🆕 CRITICAL: Request all necessary permissions
  Future<bool> requestPermissions() async {
    try {
      // 1. Request notification permission (Android 13+)
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        if (kDebugMode) {
          debugPrint('❌ Notification permission denied');
        }
        return false;
      }

      // 2. Request battery optimization exemption
      await _requestBatteryOptimizationExemption();

      // 4. iOS permissions
      if (defaultTargetPlatform == TargetPlatform.iOS) {
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

      if (kDebugMode) {
        debugPrint('✅ All permissions granted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Permission request error: $e');
      }
      return false;
    }
  }

  /// 🆕 Request battery optimization exemption (critical for background work)
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      
      if (!status.isGranted) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        
        if (result.isGranted) {
          if (kDebugMode) {
            debugPrint('✅ Battery optimization exemption granted');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Battery optimization exemption denied - notifications may not work in background');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Battery optimization request not supported: $e');
      }
    }
  }

  // ==================== ANALYTICS ====================
  
  /// Track notification opens
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
    _trackNotificationOpen(response.id ?? 0, response.payload ?? 'unknown');
  }

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
      if (kDebugMode) {
        debugPrint('📊 Analytics: Notification $notificationId opened');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Analytics error: $e');
      }
    }
  }

  // ==================== SHOW NOTIFICATION ====================
  
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
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'mindur_channel',
      channelName ?? 'Mindur Notifications',
      channelDescription: 'Notifications for journal reminders and habits',
      importance: importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
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

  String _getGroupKey(int notificationId) {
    if (notificationId >= 200 && notificationId <= 203) return 'habit_checkins';
    if (notificationId >= 100 && notificationId <= 102) return 'journal_reminders';
    if (notificationId >= 400 && notificationId <= 403) return 'engagement';
    if (notificationId >= 500 && notificationId <= 501) return 'achievements';
    return 'general';
  }

  // ==================== SMART SCHEDULING ====================
  
  /// Get smart scheduled time based on user behavior
  Future<int> _getSmartHour(String timeSlot, int defaultHour) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return defaultHour;

    try {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      
      final analytics = await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .where('openedAt', isGreaterThan: twoWeeksAgo)
          .where('type', isEqualTo: timeSlot)
          .get();

      if (analytics.docs.length < 5) return defaultHour;

      final hourCounts = <int, int>{};
      for (final doc in analytics.docs) {
        final timestamp = doc['openedAt'] as Timestamp?;
        if (timestamp != null) {
          final hour = timestamp.toDate().hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        }
      }

      if (hourCounts.isEmpty) return defaultHour;

      final mostActiveHour = hourCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      if (kDebugMode) {
        debugPrint('📊 Smart scheduling: $timeSlot shifted from $defaultHour to $mostActiveHour');
      }
      return mostActiveHour;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Smart scheduling error: $e');
      }
      return defaultHour;
    }
  }

  /// Get contextual message based on day of week
  String _getContextualMessage(String baseType, int hour) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    if (dayOfWeek == DateTime.monday && hour < 12) {
      return 'Happy Monday! Fresh start, fresh goals 🌟';
    }
    if (dayOfWeek == DateTime.wednesday) {
      return 'Hump day! You\'re halfway through the week 💪';
    }
    if (dayOfWeek == DateTime.friday && hour > 17) {
      return 'TGIF! Finish strong before the weekend 🎉';
    }
    if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      return 'Weekend mode: perfect time for self-care 🌸';
    }

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

  // ==================== GENERIC SCHEDULER ====================
  
  /// 🆕 Generic repeating notification scheduler
  Future<void> _scheduleRepeatingNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
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

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // ==================== JOURNAL REMINDERS ====================
  
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

    await _scheduleRepeatingNotification(
      id: notificationId,
      hour: hour,
      minute: minute,
      title: '📝 Time to reflect',
      body: 'Take a moment to write in your journal',
      channelId: 'journal_reminder',
      channelName: 'Journal Reminders',
      payload: 'journal_$timing',
    );

    if (kDebugMode) {
      debugPrint('✅ Journal reminder scheduled for $hour:$minute');
    }
  }

  // ==================== HABIT CHECK-INS ====================
  
  /// Schedule all 4 habit check-in notifications
  Future<void> scheduleHabitCheckIns() async {
    await cancelHabitCheckIns();

    final morningHour = await _getSmartHour('habit_morning', 7);
    final noonHour = await _getSmartHour('habit_noon', 12);
    final eveningHour = await _getSmartHour('habit_evening', 18);
    final nightHour = await _getSmartHour('habit_night', 21);

    await _scheduleRepeatingNotification(
      id: habitCheckMorning,
      hour: morningHour,
      minute: 0,
      title: '🌅 Good Morning!',
      body: _getContextualMessage('morning', morningHour),
      channelId: 'habit_checkins',
      channelName: 'Habit Check-ins',
      payload: 'habit_morning',
    );

    await _scheduleRepeatingNotification(
      id: habitCheckNoon,
      hour: noonHour,
      minute: 0,
      title: '☀️ Midday Check-in',
      body: _getContextualMessage('noon', noonHour),
      channelId: 'habit_checkins',
      channelName: 'Habit Check-ins',
      payload: 'habit_noon',
    );

    await _scheduleRepeatingNotification(
      id: habitCheckEvening,
      hour: eveningHour,
      minute: 0,
      title: '🌆 Evening Reminder',
      body: _getContextualMessage('evening', eveningHour),
      channelId: 'habit_checkins',
      channelName: 'Habit Check-ins',
      payload: 'habit_evening',
    );

    await _scheduleRepeatingNotification(
      id: habitCheckNight,
      hour: nightHour,
      minute: 0,
      title: '🌙 Goodnight Check',
      body: 'Time to wind down. Did you complete your habits today?',
      channelId: 'habit_checkins',
      channelName: 'Habit Check-ins',
      payload: 'habit_night',
    );

    if (kDebugMode) {
      debugPrint('✅ All 4 habit check-ins scheduled');
    }
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

  // ==================== STREAK PROTECTION ====================
  
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
        if (kDebugMode) {
          debugPrint('⚠️ Streak warning sent');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking streak: $e');
      }
    }
  }

  /// Schedule streak warning check (8 PM daily)
  Future<void> scheduleStreakWarningCheck() async {
    final smartHour = await _getSmartHour('streak_warning', 20);
    
    await _scheduleRepeatingNotification(
      id: streakWarning,
      hour: smartHour,
      minute: 0,
      title: '⚠️ Streak Check',
      body: 'Checking your journal streak...',
      channelId: 'streak_protection',
      channelName: 'Streak Protection',
      payload: 'streak_warning',
    );

    if (kDebugMode) {
      debugPrint('✅ Streak warning check scheduled for $smartHour PM daily');
    }
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

  // ==================== ACHIEVEMENTS ====================
  
  /// Check and send achievement badges
  Future<void> checkAndSendAchievementBadges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final journalCount = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .count()
          .get();
      
      final totalJournals = journalCount.count ?? 0;
      
      await _checkJournalMilestone(totalJournals);
      await _checkStreakMilestone(uid);
      await _checkHabitMilestone(uid);
      await _checkPerfectWeek(uid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Achievement check error: $e');
      }
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
      
      await _saveBadge('journal_$count', badge, message);
    }
  }

  Future<void> _checkStreakMilestone(String uid) async {
    // Called from home_screen already
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
      if (kDebugMode) {
        debugPrint('Habit milestone error: $e');
      }
    }
  }

  Future<void> _checkPerfectWeek(String uid) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      
      final journalDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .where('timestamp', isGreaterThan: weekStart)
          .get();
      
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
      if (kDebugMode) {
        debugPrint('Perfect week check error: $e');
      }
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
      if (kDebugMode) {
        debugPrint('🏆 Badge saved: $badgeId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Badge save error: $e');
      }
    }
  }

  // ==================== DAILY SUMMARY ====================
  
  /// Send daily completion summary
  Future<void> sendDailySummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final journalCount = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .where('timestamp', isGreaterThanOrEqualTo: today)
          .count()
          .get();

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

      final streakDoc = await _db.collection('users').doc(uid).get();
      final streakData = streakDoc.data()?['journalStreak'] as Map?;
      final currentStreak = streakData?['currentStreak'] ?? 0;

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

      if (kDebugMode) {
        debugPrint('📊 Daily summary sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Daily summary error: $e');
      }
    }
  }

  /// Schedule daily summary (10:30 PM)
  Future<void> scheduleDailySummary() async {
    await _scheduleRepeatingNotification(
      id: dailySummary,
      hour: 22,
      minute: 30,
      title: '📊 Today\'s Summary',
      body: 'See how you did today',
      channelId: 'summary',
      channelName: 'Daily Summaries',
      payload: 'daily_summary',
    );

    if (kDebugMode) {
      debugPrint('✅ Daily summary scheduled for 10:30 PM');
    }
  }

  // ==================== ENGAGEMENT NOTIFICATIONS ====================
  
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
      'engagement',
      'Weekly Reviews',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      weeklyReview,
      '📊 Your Weekly Review',
      'Take a moment to reflect on this week. What went well? What can improve?',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_review',
    );

    if (kDebugMode) {
      debugPrint('✅ Weekly review scheduled for Sundays at 7 PM');
    }
  }

  /// Schedule motivational quote (random time between 10 AM - 5 PM)
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

    final random = Random();
    final randomHour = 10 + random.nextInt(7);
    final selectedQuote = quotes[random.nextInt(quotes.length)];

    await _scheduleRepeatingNotification(
      id: motivationalQuote,
      hour: randomHour,
      minute: 0,
      title: '💭 Daily Inspiration',
      body: selectedQuote,
      channelId: 'engagement',
      channelName: 'Motivational Quotes',
      payload: 'motivational_quote',
    );

    if (kDebugMode) {
      debugPrint('✅ Motivational quote scheduled');
    }
  }

  /// Schedule mid-week check-in (Wednesday 12 PM)
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
      'engagement',
      'Mid-week Check-ins',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      midWeekCheckIn,
      '🎯 Mid-Week Check-in',
      'You\'re halfway through the week! How are you feeling? Take a moment to journal.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'midweek_checkin',
    );

    if (kDebugMode) {
      debugPrint('✅ Mid-week check-in scheduled for Wednesdays at 12 PM');
    }
  }

  /// Schedule weekend reflection (Saturday 10 AM)
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
      'engagement',
      'Weekend Reflections',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      weekendReflection,
      '🌈 Weekend Reflection',
      'It\'s the weekend! Take time to relax and reflect on your journey.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekend_reflection',
    );

    if (kDebugMode) {
      debugPrint('✅ Weekend reflection scheduled for Saturdays at 10 AM');
    }
  }

  // ==================== SCHEDULE ALL ====================
  
  /// Schedule all app notifications at once
  Future<void> scheduleAllNotifications(String journalTiming) async {
    if (kDebugMode) {
      debugPrint('📅 Scheduling all notifications with smart features...');
    }
    
    await scheduleJournalReminder(journalTiming);
    await scheduleHabitCheckIns();
    await scheduleStreakWarningCheck();
    await scheduleWeeklyReview();
    await scheduleMotivationalQuote();
    await scheduleMidWeekCheckIn();
    await scheduleWeekendReflection();
    await scheduleDailySummary();
    
    if (kDebugMode) {
      debugPrint('✅ All notifications scheduled with smart scheduling!');
    }
  }

  // ==================== CANCELLATION ====================
  
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
    if (kDebugMode) {
      debugPrint('✅ All notifications cancelled');
    }
  }

  // ==================== UTILITIES ====================
  
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