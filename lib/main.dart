import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
// NEW THEME
import 'theme/theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage
  await Hive.initFlutter();

  // Load env for all platforms
  await dotenv.load(fileName: ".env");

  // 🔥 Load saved theme (System / Light / Dark)
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

          // ✅ Your existing themes (UNCHANGED)
          theme: MindurTheme.lightTheme(),
          darkTheme: MindurTheme.darkTheme(),

          // ✅ Now fully dynamic
          themeMode: mode,

          home: const FirebaseInitWrapper(),
        );
      },
    );
  }
}

class FirebaseInitWrapper extends StatefulWidget {
  const FirebaseInitWrapper({super.key});

  @override
  State<FirebaseInitWrapper> createState() => _FirebaseInitWrapperState();
}

class _FirebaseInitWrapperState extends State<FirebaseInitWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Auth persistence error: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user != null ? const MainScreen() : const LoginScreen();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
