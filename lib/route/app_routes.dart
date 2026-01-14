import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/personalization_screen.dart';
import '../screens/main_screen.dart';
import '../screens/account_screen.dart';
import '../screens/journal_edit_screen.dart';
import '../screens/food_search_screen.dart';
import '../screens/AddFoodEntryScreen.dart';
import '../services/analytics_service.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String personalization = '/personalization';
  static const String home = '/';
  static const String account = '/account';
  static const String journalEdit = '/journal/edit';
  static const String journalNew = '/journal/new';
  static const String foodSearch = '/food/search';
  static const String foodAdd = '/food/add';

  /// 🔐 Check if user is authenticated
  static bool _isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// 🎯 GoRouter configuration
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: login,
    
    // 🔄 Refresh router when auth state changes
    refreshListenable: _AuthStateNotifier(),
    
    redirect: (context, state) async {
      final isAuthenticated = _isAuthenticated();
      final isOnAuthPage = state.matchedLocation == login || 
                          state.matchedLocation == signup;
      final isOnPersonalization = state.matchedLocation == personalization;

      // ✅ LOG SCREEN VIEW
      AnalyticsService().logScreenView(state.matchedLocation);

      // ✅ User is authenticated
      if (isAuthenticated) {
        // Check if user completed personalization
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            final personalizedCompleted = userDoc.data()?['personalizedCompleted'] ?? false;
            
            // User hasn't completed personalization yet
            if (!personalizedCompleted) {
              // If they're trying to access anything OTHER than personalization
              if (!isOnPersonalization) {
                debugPrint('🔄 Redirecting to personalization (not completed)');
                return personalization;
              }
              // They're on personalization screen, allow it
              return null;
            }
            
            // User HAS completed personalization
            if (personalizedCompleted) {
              // If they're on auth pages or personalization, redirect to home
              if (isOnAuthPage || isOnPersonalization) {
                debugPrint('🔄 Redirecting to home (already personalized)');
                return home;
              }
              // Allow access to all other screens
              return null;
            }
          } catch (e) {
            debugPrint('⚠️ Error checking personalization status: $e');
            // On error, allow navigation
            return null;
          }
        }
        
        // Default: redirect auth pages to home, allow everything else
        if (isOnAuthPage) {
          return home;
        }
        return null;
      }

      // ❌ User is NOT authenticated
      if (!isOnAuthPage && !isOnPersonalization) {
        debugPrint('🔄 Redirecting to login (not authenticated)');
        return login; // Redirect to login
      }

      return null; // Allow access to login/signup
    },

    routes: [
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
        const begin = Offset(1.0, 0.0); // Slide from right
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween<double>(begin: 0.0, end: 1.0),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
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
