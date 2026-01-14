import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'route/app_routes.dart';

import 'services/boot_receiver_handler.dart';
import 'services/api_config_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';  // ✅ IMPORT

import 'theme/theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();
  await AppThemeController.loadTheme();

  // ✅ Initialize Firebase and Analytics
  await _initializeApp();

  runApp(const MyApp());
}

/// Initialize all services before app starts
Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // ✅ SETUP CRASHLYTICS
    if (!kIsWeb) {
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }

    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (_) {}
    }

    await ApiConfigService.load();
    debugPrint('✅ API config loaded');

    await NotificationService().initialize();
    debugPrint('✅ Notification service initialized');

    await BootReceiverHandler().rescheduleNotificationsAfterBoot();
    debugPrint('✅ Notifications rescheduled');

    // ✅ LOG APP OPEN (tracks DAU automatically)
    await AnalyticsService().logAppOpen();
    debugPrint('✅ Analytics initialized');

    // ✅ SET USER ID if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await AnalyticsService().setUserId(user.uid);
    }

    FlutterNativeSplash.remove();
  } catch (e, stackTrace) {
    debugPrint('❌ Initialization error: $e');
    
    // ✅ LOG ERROR TO CRASHLYTICS
    await AnalyticsService().logError(
      error: e.toString(),
      stackTrace: stackTrace,
      reason: 'App initialization failed',
    );
    
    FlutterNativeSplash.remove();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Mind-ur',
          debugShowCheckedModeBanner: false,
          theme: MindurTheme.lightTheme(),
          darkTheme: MindurTheme.darkTheme(),
          themeMode: mode,
          routerConfig: AppRoutes.router,
        );
      },
    );
  }
}