import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Handles rescheduling notifications after device boot or app restart
class BootReceiverHandler {
  static final BootReceiverHandler _instance = BootReceiverHandler._internal();
  factory BootReceiverHandler() => _instance;
  BootReceiverHandler._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call this from main.dart after Firebase initialization
  Future<void> rescheduleNotificationsAfterBoot() async {
    try {
      if (kDebugMode) {
        debugPrint('🔔 Rescheduling notifications after boot/startup...');
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No authenticated user - skipping reschedule');
        }
        return;
      }

      // Get user preferences
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ User document does not exist - skipping reschedule');
        }
        return;
      }

      final data = userDoc.data();
      if (data == null) return;

      // Check if notifications are enabled
      final notificationsEnabled = data['notificationsEnabled'] ?? true;
      if (!notificationsEnabled) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Notifications disabled in preferences - skipping reschedule',
          );
        }
        return;
      }

      // Get journal reminder timing
      final journalReminder = data['journalReminder'] ?? 'Evening';

      if (kDebugMode) {
        debugPrint(
          '🔔 Notifications enabled. Journal reminder time: $journalReminder',
        );
      }

      // Initialize notification service (creates channels)
      await _notificationService.initialize();

      // Reschedule all notifications
      await _notificationService.scheduleAllNotifications(journalReminder);

      if (kDebugMode) {
        debugPrint('✅ Notifications rescheduled successfully');
      }

      // Log reschedule event for analytics
      await _logRescheduleEvent();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error rescheduling notifications: $e');
      }
    }
  }

  /// Log the reschedule event to Firestore for analytics
  Future<void> _logRescheduleEvent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notification_analytics')
          .add({
            'event': 'notifications_rescheduled_after_boot',
            'timestamp': FieldValue.serverTimestamp(),
            'device': 'android',
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error logging reschedule event: $e');
      }
    }
  }

  /// Check if notifications need rescheduling (useful for diagnostics)
  Future<bool> needsRescheduling() async {
    try {
      final pending = await _notificationService.getPendingNotifications();

      // If no pending notifications, we need to reschedule
      if (pending.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No pending notifications found');
        }
        return true;
      }

      if (kDebugMode) {
        debugPrint(
          '✅ Found ${pending.length} pending notifications - no reschedule needed',
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking pending notifications: $e');
      }
      return true; // Assume needs rescheduling on error
    }
  }
}
