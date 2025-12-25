import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  static const int journalReminderMorning = 100;
  static const int journalReminderEvening = 101;
  static const int journalReminderNight = 102;
  static const int habitReminder = 200;
  static const int streakReminder = 300;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Set local location (India)
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
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

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on payload
    // You can emit this through a stream/callback to handle navigation
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
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
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mindur_channel',
      'Mind-ur Notifications',
      channelDescription: 'Notifications for journal reminders and habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule daily journal reminder
  Future<void> scheduleJournalReminder(String timing) async {
    // Cancel existing reminders
    await cancelJournalReminders();

    int hour, minute, notificationId;

    switch (timing.toLowerCase()) {
      case 'morning':
        hour = 8;
        minute = 0;
        notificationId = journalReminderMorning;
        break;
      case 'evening':
        hour = 18;
        minute = 0;
        notificationId = journalReminderEvening;
        break;
      case 'nightly':
        hour = 21;
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

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'journal_reminder',
      'Journal Reminders',
      channelDescription: 'Daily reminders to write in your journal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
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
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    debugPrint('✅ Journal reminder scheduled for $hour:$minute');
  }

  /// Schedule habit reminder (9 AM daily)
  Future<void> scheduleHabitReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_reminder',
      'Habit Reminders',
      channelDescription: 'Daily reminders to complete your habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      habitReminder,
      '💪 Daily habits',
      'Don\'t forget to complete your habits today!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ Habit reminder scheduled');
  }

  /// Schedule streak milestone notification
  Future<void> scheduleStreakMilestone(int streakDays) async {
    if (streakDays % 7 == 0 && streakDays > 0) {
      // Celebrate weekly milestones
      await showNotification(
        id: streakReminder,
        title: '🔥 Amazing streak!',
        body:
            'You\'ve maintained a $streakDays day journal streak! Keep it up!',
        payload: 'streak_milestone',
      );
    }
  }

  /// Cancel all journal reminders
  Future<void> cancelJournalReminders() async {
    await _notifications.cancel(journalReminderMorning);
    await _notifications.cancel(journalReminderEvening);
    await _notifications.cancel(journalReminderNight);
    debugPrint('✅ Journal reminders cancelled');
  }

  /// Cancel habit reminders
  Future<void> cancelHabitReminders() async {
    await _notifications.cancel(habitReminder);
    debugPrint('✅ Habit reminders cancelled');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show test notification
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'Your notifications are working perfectly!',
      payload: 'test',
    );
  }
}
