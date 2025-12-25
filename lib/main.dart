import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

import 'services/api_config_service.dart';
import 'services/notification_service.dart';

import 'theme/theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📦 Local storage
  await Hive.initFlutter();

  // 🎨 Load saved theme
  await AppThemeController.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Mind-ur',
          debugShowCheckedModeBanner: false,
          theme: MindurTheme.lightTheme(),
          darkTheme: MindurTheme.darkTheme(),
          themeMode: mode,
          home: const AppInitGate(),
        );
      },
    );
  }
}

class AppInitGate extends StatefulWidget {
  const AppInitGate({super.key});

  @override
  State<AppInitGate> createState() => _AppInitGateState();
}

class _AppInitGateState extends State<AppInitGate> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 🔥 Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🌐 Web auth persistence
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (_) {}
    }

    // 🔑 Load API keys
    await ApiConfigService.load();

    // 🔔 Notifications
    await NotificationService().initialize();

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      _fadeScaleRoute(
        user != null ? const MainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Native splash stays visible here
    return const SizedBox.shrink();
  }
}

/// 🎬 Fade + subtle scale transition
PageRouteBuilder _fadeScaleRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      final scale = Tween<double>(
        begin: 0.98,
        end: 1.0,
      ).animate(fade);

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}
