import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'route/app_routes.dart';

import 'services/boot_receiver_handler.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/connectivity_service.dart';

import 'screens/no_internet_screen.dart';

import 'theme/theme.dart';
import 'theme/theme_controller.dart';

/// ✅ Debug-only logger
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();
  await AppThemeController.loadTheme();

  await _initializeApp();

  runApp(const MyApp());
}

/// Initialize all services before app starts
Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logDebug('✅ Firebase initialized');

    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }

    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (_) {}
    }

    await NotificationService().initialize();
    logDebug('✅ Notification service initialized');

    await BootReceiverHandler().rescheduleNotificationsAfterBoot();
    logDebug('✅ Notifications rescheduled');

    await AnalyticsService().logAppOpen();
    logDebug('✅ Analytics initialized');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await AnalyticsService().setUserId(user.uid);
    }

    await ConnectivityService().initialize();
    logDebug('✅ Connectivity service initialized');

    FlutterNativeSplash.remove();
  } catch (e, stackTrace) {
    logDebug('❌ Initialization error: $e');

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
          builder: (context, child) {
            return ConnectivityMonitor(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  } 
}

/// ✅ Global connectivity monitor
class ConnectivityMonitor extends StatefulWidget {
  final Widget child;

  const ConnectivityMonitor({super.key, required this.child});

  @override
  State<ConnectivityMonitor> createState() => _ConnectivityMonitorState();
}

class _ConnectivityMonitorState extends State<ConnectivityMonitor> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();

    _hasInternet = ConnectivityService().isConnected;

    ConnectivityService().connectionStatus.listen((isConnected) {
      if (mounted && _hasInternet != isConnected) {
        setState(() {
          _hasInternet = isConnected;
        });

        logDebug(
          _hasInternet
              ? '✅ Internet restored - hiding overlay'
              : '❌ No internet - showing overlay',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_hasInternet) const Positioned.fill(child: NoInternetScreen()),
      ],
    );
  }
}
