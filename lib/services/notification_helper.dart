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
            completedDate = DateTime.tryParse(lastCompletedAt) ?? DateTime.now();
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

      debugPrint('✅ Habit notification sent: $completedHabits/$totalHabits');
    } catch (e) {
      debugPrint('❌ Error checking habits: $e');
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
        'openRate': totalOpened > 0 ? (totalOpened / 14).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      debugPrint('Analytics fetch error: $e');
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
      debugPrint('Badge fetch error: $e');
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
      debugPrint('🗑️ Cleared ${oldDocs.docs.length} old analytics entries');
    } catch (e) {
      debugPrint('Analytics cleanup error: $e');
    }
  }
}