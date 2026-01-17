import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/notification_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/personalization_screen.dart';
import '../screens/main_screen.dart';
import '../screens/account_screen.dart';
import '../screens/journal_edit_screen.dart';
import '../screens/food_search_screen.dart';
import '../screens/AddFoodEntryScreen.dart';
import '../services/analytics_service.dart';

/// ✅ Debug-only logger
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String personalization = '/personalization';
  static const String home = '/';
  static const String account = '/account';
  static const String journalEdit = '/journal/edit';
  static const String journalNew = '/journal/new';
  static const String foodSearch = '/food/search';
  static const String foodAdd = '/food/add';
  static const String notifications = '/notifications';

  static bool _isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static Future<bool> _isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: kDebugMode, // ✅ IMPORTANT
    initialLocation: onboarding,
    refreshListenable: _AuthStateNotifier(),

    redirect: (context, state) async {
      final isAuthenticated = _isAuthenticated();
      final isOnboardingCompleted = await _isOnboardingCompleted();

      final isOnOnboardingPage = state.matchedLocation == onboarding;
      final isOnAuthPage =
          state.matchedLocation == login || state.matchedLocation == signup;
      final isOnPersonalization = state.matchedLocation == personalization;

      AnalyticsService().logScreenView(state.matchedLocation);

      if (!isOnboardingCompleted && !isOnOnboardingPage) {
        logDebug('🔄 Redirecting to onboarding (not completed)');
        return onboarding;
      }

      if (isOnboardingCompleted && isOnOnboardingPage) {
        if (isAuthenticated) {
          logDebug('🔄 Onboarding done → home');
          return home;
        } else {
          logDebug('🔄 Onboarding done → login');
          return login;
        }
      }

      if (isAuthenticated) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            final personalizedCompleted =
                userDoc.data()?['personalizedCompleted'] ?? false;

            if (!personalizedCompleted) {
              if (!isOnPersonalization) {
                logDebug('🔄 Redirecting to personalization');
                return personalization;
              }
              return null;
            }

            if (personalizedCompleted) {
              if (isOnAuthPage || isOnPersonalization) {
                logDebug('🔄 Already personalized → home');
                return home;
              }
              return null;
            }
          } catch (e) {
            logDebug('⚠️ Personalization check error: $e');
            return null;
          }
        }

        if (isOnAuthPage) return home;
        return null;
      }

      if (!isOnAuthPage && !isOnPersonalization && !isOnOnboardingPage) {
        logDebug('🔄 Not authenticated → login');
        return login;
      }

      return null;
    },
    routes: [
      // ✅ NEW: ONBOARDING ROUTE
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // 🔐 AUTH ROUTES
      GoRoute(
        path: login,
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),

      GoRoute(
        path: signup,
        name: 'signup',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const SignupScreen(),
        ),
      ),

      GoRoute(
        path: personalization,
        name: 'personalization',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const PersonalizationScreen(),
        ),
      ),

      // 🏠 MAIN APP (with bottom nav)
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const MainScreen(),
        ),
      ),

      // 👤 ACCOUNT
      GoRoute(
        path: account,
        name: 'account',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const AccountScreen(),
        ),
      ),

      // 📝 JOURNAL ROUTES
      GoRoute(
        path: journalNew,
        name: 'journal-new',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const JournalEditScreen(),
        ),
      ),

      GoRoute(
        path: '$journalEdit/:id',
        name: 'journal-edit',
        pageBuilder: (context, state) {
          final documentId = state.pathParameters['id']!;
          return _buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: JournalEditScreen(documentId: documentId),
          );
        },
      ),

      // 🍔 FOOD ROUTES
      GoRoute(
        path: foodSearch,
        name: 'food-search',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const FoodSearchSceen(),
        ),
      ),

      GoRoute(
        path: foodAdd,
        name: 'food-add',
        pageBuilder: (context, state) => _buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const FoodLoggingScreen(),
        ),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        pageBuilder: (context, state) {
          return _buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const NotificationScreen(),
          );
        },
      ),
    ],

    // 🚫 ERROR PAGE
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  /// 🎬 Custom page transition
  static CustomTransitionPage _buildPageWithDefaultTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }
}

/// 🔔 Notifier to refresh router when auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }
}
