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
      debugPrint('🔄 Checking if notifications need rescheduling...');

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('⚠️ No user logged in, skipping notification rescheduling');
        return;
      }

      // Get user preferences
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        debugPrint('⚠️ User document not found');
        return;
      }

      final data = userDoc.data();
      if (data == null) return;

      // Check if notifications are enabled
      final notificationsEnabled = data['notificationsEnabled'] ?? true;
      if (!notificationsEnabled) {
        debugPrint('🔕 Notifications disabled by user');
        return;
      }

      // Get journal reminder timing
      final journalReminder = data['journalReminder'] ?? 'Evening';

      debugPrint('🔄 Rescheduling all notifications...');

      // Initialize notification service (creates channels)
      await _notificationService.initialize();

      // Reschedule all notifications
      await _notificationService.scheduleAllNotifications(journalReminder);

      debugPrint('✅ All notifications rescheduled successfully after boot');

      // Log reschedule event for analytics
      await _logRescheduleEvent();
    } catch (e) {
      debugPrint('❌ Error rescheduling notifications: $e');
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
      debugPrint('Failed to log reschedule event: $e');
    }
  }

  /// Check if notifications need rescheduling (useful for diagnostics)
  Future<bool> needsRescheduling() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      
      // If no pending notifications, we need to reschedule
      if (pending.isEmpty) {
        debugPrint('⚠️ No pending notifications found - needs rescheduling');
        return true;
      }

      debugPrint('✅ Found ${pending.length} pending notifications');
      return false;
    } catch (e) {
      debugPrint('Error checking pending notifications: $e');
      return true; // Assume needs rescheduling on error
    }
  }
}