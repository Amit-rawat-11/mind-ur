import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/// Helper class for notification-related operations
class NotificationHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  /// Check habits and send personalized notification
  static Future<void> checkHabitsAndNotify() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      if (snapshot.docs.isEmpty) return;

      int totalHabits = 0;
      int completedHabits = 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalHabits++;

        final lastCompletedAt = data['lastCompletedAt'];
        final isCompleted = data['isCompleted'] ?? false;

        if (isCompleted && lastCompletedAt != null) {
          DateTime completedDate;

          if (lastCompletedAt is Timestamp) {
            completedDate = lastCompletedAt.toDate();
          } else if (lastCompletedAt is String) {
            completedDate =
                DateTime.tryParse(lastCompletedAt) ?? DateTime.now();
          } else {
            continue;
          }

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

      await _notificationService.sendHabitCompletionNotification(
        allCompleted: completedHabits == totalHabits,
        completedCount: completedHabits,
        totalCount: totalHabits,
      );

      if (kDebugMode) {
        debugPrint(
          '📊 Habit check: $completedHabits/$totalHabits completed. Notification sent.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking habits for notification: $e');
      }
    }
  }

  /// Check journal streak and send warning if needed
  static Future<void> checkStreakAndWarn() async {
    await _notificationService.checkAndSendStreakWarning();
  }

  /// Check achievements and send badge notifications
  static Future<void> checkAchievements() async {
    await _notificationService.checkAndSendAchievementBadges();
  }

  /// Send daily summary at end of day
  static Future<void> sendDailySummary() async {
    await _notificationService.sendDailySummary();
  }

  /// Get notification analytics for user
  static Future<Map<String, dynamic>> getNotificationAnalytics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    try {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .where('openedAt', isGreaterThan: twoWeeksAgo)
          .get();

      // Calculate stats
      final totalOpened = snapshot.docs.length;
      final byType = <String, int>{};
      final byHour = <int, int>{};

      for (final doc in snapshot.docs) {
        final type = doc['type'] as String? ?? 'unknown';
        final timestamp = doc['openedAt'] as Timestamp?;

        byType[type] = (byType[type] ?? 0) + 1;

        if (timestamp != null) {
          final hour = timestamp.toDate().hour;
          byHour[hour] = (byHour[hour] ?? 0) + 1;
        }
      }

      // Find most active hour
      int mostActiveHour = 12;
      int maxCount = 0;
      byHour.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          mostActiveHour = hour;
        }
      });

      return {
        'totalOpened': totalOpened,
        'byType': byType,
        'byHour': byHour,
        'mostActiveHour': mostActiveHour,
        'openRate': totalOpened > 0
            ? (totalOpened / 14).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error fetching notification analytics: $e');
      }
      return {};
    }
  }

  /// Get user's earned badges
  static Future<List<Map<String, dynamic>>> getUserBadges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('badges')
          .orderBy('earnedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'emoji': data['emoji'] ?? '🏆',
          'title': data['title'] ?? 'Achievement',
          'earnedAt': data['earnedAt'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error fetching user badges: $e');
      }
      return [];
    }
  }

  /// Clear old analytics data (keep last 30 days)
  static Future<void> clearOldAnalytics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .where('openedAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _db.batch();
      for (final doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      if (kDebugMode) {
        debugPrint('✅ Old notification analytics cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error clearing old analytics: $e');
      }
    }
  }
  /// Get aggregated activity feed (Badges, Analytics, Journals, Habits)
  static Future<List<Map<String, dynamic>>> getActivityFeed() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final List<Map<String, dynamic>> activities = [];

      // 1. Fetch Badges (Achievements)
      final badgesSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('badges')
          .orderBy('earnedAt', descending: true)
          .limit(20)
          .get();

      for (final doc in badgesSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'id': doc.id,
          'type': 'achievement',
          'title': '${data['emoji'] ?? '🏆'} ${data['title'] ?? 'Achievement'}',
          'body': 'You earned a new badge!',
          'timestamp':
              (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isRead': true, // Badges are usually seen immediately
        });
      }

      // 2. Fetch Notification Analytics (Interactions)
      final analyticsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .orderBy('openedAt', descending: true)
          .limit(20)
          .get();

      for (final doc in analyticsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'notification';

        // Map types to display strings
        String title = 'Notification';
        String body = 'You interacted with a notification.';

        if (type.toString().contains('journal')) {
          title = '📝 Journal Reminder';
          body = 'Time to reflect was handled.';
        } else if (type.toString().contains('habit')) {
          title = '✓ Habit Check-in';
          body = 'Habit check-in completed.';
        } else if (type.toString().contains('streak')) {
          title = '🔥 Streak Alert';
          body = 'Streak protection active.';
        } else if (type.toString().contains('summary')) {
          title = '📊 Daily Summary';
          body = 'You checked your daily summary.';
        }

        activities.add({
          'id': doc.id,
          'type': _mapTypeToCategory(type),
          'title': title,
          'body': body,
          'timestamp':
              (data['openedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isRead': true,
        });
      }

      // 3. Fetch Recent Journals
      final journalsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (final doc in journalsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'id': doc.id,
          'type': 'summary', // Classify as summary/activity
          'title': '📝 Journal Entry',
          'body': data['title'] ?? 'New entry created',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isRead': true,
        });
      }

      // 4. Fetch Completed Habits (Approximation based on 'lastCompletedAt')
      // Note: This only gets the *latest* completion per habit or requires a subcollection for history.
      // For now, we'll use the 'habits' collection.
      final habitsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .where('isCompleted', isEqualTo: true)
          .get();

      for (final doc in habitsSnapshot.docs) {
        final data = doc.data();
        if (data['lastCompletedAt'] != null) {
          activities.add({
            'id': doc.id,
            'type': 'reminder', // Classify as reminder/habit
            'title': '✓ Habit Completed',
            'body': 'You completed "${data['title']}"',
            'timestamp': (data['lastCompletedAt'] as Timestamp).toDate(),
            'isRead': true,
          });
        }
      }

      // Sort by timestamp descending
      activities.sort((a, b) => (b['timestamp'] as DateTime)
          .compareTo(a['timestamp'] as DateTime));

      return activities;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error fetching activity feed: $e');
      }
      return [];
    }
  }

  static String _mapTypeToCategory(String type) {
    if (type.contains('achievement') || type.contains('badge'))
      return 'achievement';
    if (type.contains('streak')) return 'streak';
    if (type.contains('summary') || type.contains('journal')) return 'summary';
    return 'reminder';
  }
}
