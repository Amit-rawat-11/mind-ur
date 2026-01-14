import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 📊 Centralized Analytics Service
/// 
/// HOW IT WORKS:
/// 1. Singleton pattern - only one instance exists
/// 2. Wraps Firebase Analytics for easy event tracking
/// 3. Automatically tracks user properties
/// 4. Logs errors to Crashlytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Get the observer for route tracking
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(
        analytics: _analytics,
      );

  // ═══════════════════════════════════════════════════════════
  // USER PROPERTIES (Stored with user for segmentation)
  // ═══════════════════════════════════════════════════════════

  /// Set user ID when they log in
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
    }
  }

  /// Set user properties (fitness goal, premium status, etc)
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Update all user properties at once
  Future<void> setUserProperties({
    String? fitnessGoal,
    String? appGoal,
    String? notificationPreference,
    bool? isPremium,
    int? journalStreak,
    int? habitStreak,
  }) async {
    if (fitnessGoal != null) {
      await setUserProperty('fitness_goal', fitnessGoal);
    }
    if (appGoal != null) {
      await setUserProperty('app_goal', appGoal);
    }
    if (notificationPreference != null) {
      await setUserProperty('notification_pref', notificationPreference);
    }
    if (isPremium != null) {
      await setUserProperty('is_premium', isPremium ? 'true' : 'false');
    }
    if (journalStreak != null) {
      await setUserProperty('journal_streak', journalStreak.toString());
    }
    if (habitStreak != null) {
      await setUserProperty('habit_streak', habitStreak.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SESSION TRACKING
  // ═══════════════════════════════════════════════════════════

  /// Log app open (tracks DAU automatically)
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    debugPrint('📊 Analytics: App opened');
  }

  

  // ═══════════════════════════════════════════════════════════
  // SCREEN TRACKING (Automatic via GoRouter + Manual)
  // ═══════════════════════════════════════════════════════════

  /// Log screen view manually (GoRouter does this automatically)
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    debugPrint('📊 Analytics: Screen viewed - $screenName');
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH & ONBOARDING EVENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> logSignup({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logPersonalizationCompleted({
    required String fitnessGoal,
    required String appGoal,
    required String notificationTime,
  }) async {
    await _analytics.logEvent(
      name: 'personalization_completed',
      parameters: {
        'fitness_goal': fitnessGoal,
        'app_goal': appGoal,
        'notification_time': notificationTime,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // JOURNAL EVENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> logJournalCreated({
    required int wordCount,
    required String timeOfDay,
  }) async {
    await _analytics.logEvent(
      name: 'journal_created',
      parameters: {
        'word_count': wordCount,
        'time_of_day': timeOfDay,
        'day_of_week': DateTime.now().weekday,
      },
    );
  }

  Future<void> logJournalEdited({required String entryId}) async {
    await _analytics.logEvent(
      name: 'journal_edited',
      parameters: {'entry_id': entryId},
    );
  }

  Future<void> logJournalDeleted() async {
    await _analytics.logEvent(name: 'journal_deleted');
  }

  Future<void> logJournalStreakMilestone({required int streakDays}) async {
    await _analytics.logEvent(
      name: 'journal_streak_milestone',
      parameters: {'streak_days': streakDays},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HABIT EVENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> logHabitCreated({
    required String priority,
    required String habitName,
  }) async {
    await _analytics.logEvent(
      name: 'habit_created',
      parameters: {
        'priority': priority,
        'habit_name': habitName,
      },
    );
  }

  Future<void> logHabitCompleted({
    required String habitName,
    required int streakDays,
  }) async {
    await _analytics.logEvent(
      name: 'habit_completed',
      parameters: {
        'habit_name': habitName,
        'streak_days': streakDays,
        'time_of_day': DateTime.now().hour,
        'day_of_week': DateTime.now().weekday,
      },
    );
  }

  Future<void> logHabitDeleted({required int daysActive}) async {
    await _analytics.logEvent(
      name: 'habit_deleted',
      parameters: {'days_active': daysActive},
    );
  }

  Future<void> logDailyHabitsSummary({
    required int completed,
    required int total,
  }) async {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;
    await _analytics.logEvent(
      name: 'daily_habits_summary',
      parameters: {
        'completed': completed,
        'total': total,
        'completion_percentage': percentage,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOD TRACKING EVENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> logFoodLogged({
    required String foodName,
    required int calories,
    required int protein,
  }) async {
    await _analytics.logEvent(
      name: 'food_logged',
      parameters: {
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'time_of_day': DateTime.now().hour,
      },
    );
  }

  Future<void> logCalorieGoalReached({required int totalCalories}) async {
    await _analytics.logEvent(
      name: 'calorie_goal_reached',
      parameters: {'total_calories': totalCalories},
    );
  }

  Future<void> logProteinGoalReached({required int totalProtein}) async {
    await _analytics.logEvent(
      name: 'protein_goal_reached',
      parameters: {'total_protein': totalProtein},
    );
  }

  Future<void> logFoodSearch({required String query}) async {
    await _analytics.logEvent(
      name: 'food_search',
      parameters: {'search_query': query},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AI CHAT EVENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> logChatSessionStarted() async {
    await _analytics.logEvent(name: 'chat_session_started');
  }

  Future<void> logChatMessageSent({required int messageLength}) async {
    await _analytics.logEvent(
      name: 'chat_message_sent',
      parameters: {'message_length': messageLength},
    );
  }

  Future<void> logChatSessionEnded({
    required Duration duration,
    required int messageCount,
  }) async {
    await _analytics.logEvent(
      name: 'chat_session_ended',
      parameters: {
        'duration_seconds': duration.inSeconds,
        'message_count': messageCount,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION EVENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> logNotificationReceived({required String type}) async {
    await _analytics.logEvent(
      name: 'notification_received',
      parameters: {'notification_type': type},
    );
  }

  Future<void> logNotificationOpened({required String type}) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {'notification_type': type},
    );
  }

  Future<void> logNotificationDismissed({required String type}) async {
    await _analytics.logEvent(
      name: 'notification_dismissed',
      parameters: {'notification_type': type},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ERROR & CRASH TRACKING
  // ═══════════════════════════════════════════════════════════

  /// Log non-fatal errors
  Future<void> logError({
    required String error,
    StackTrace? stackTrace,
    String? reason,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );

    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_message': error.toString(),
        'reason': reason ?? 'unknown',
      },
    );
  }

  /// Log fatal crashes
  Future<void> logCrash({
    required dynamic exception,
    required StackTrace stackTrace,
    String? reason,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: true,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PREMIUM/MONETIZATION (Future)
  // ═══════════════════════════════════════════════════════════

  Future<void> logPremiumTrialStarted() async {
    await _analytics.logEvent(name: 'premium_trial_started');
  }

  Future<void> logPremiumUpgrade({required String plan}) async {
    await _analytics.logEvent(
      name: 'premium_upgraded',
      parameters: {'plan': plan},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOM EVENTS (For any other tracking needs)
  // ═══════════════════════════════════════════════════════════

  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }
}