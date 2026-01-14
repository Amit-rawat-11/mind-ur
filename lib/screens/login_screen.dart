import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/input_textfield.dart';
import '../services/analytics_service.dart';
import '../services/signup_service.dart';
import '../screens/signup_screen.dart';
import '../screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final SignupService signupService = SignupService();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter both email and password.', isError: false);
      return;
    }

    setState(() => isLoading = true);

    final String? result = await signupService.login(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result == null) {
      // ✅ LOG SUCCESSFUL LOGIN
      await AnalyticsService().logLogin(method: 'email');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await AnalyticsService().setUserId(user.uid);
      }

      context.go('/');
    } else {
      _showSnack(result, isError: true);

      // ✅ LOG LOGIN ERROR
      await AnalyticsService().logError(error: result, reason: 'Login failed');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final size = MediaQuery.of(context).size;

    return AppBackground(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Illustration (optional but clean)
                Center(
                  child: SvgPicture.asset(
                    'assets/images/svg/secure_login.svg',
                    height: 220,
                  ),
                ),

                const SizedBox(height: 32),

                Text('Welcome back', style: theme.textTheme.headlineLarge),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue your journey.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                InputTextfield(
                  autofillHints: const [AutofillHints.email],
                  labelText: 'Email',
                  controller: emailController,
                  isPassword: false,
                ),

                const SizedBox(height: 20),

                InputTextfield(
                  autofillHints: const [AutofillHints.password],
                  labelText: 'Password',
                  controller: passwordController,
                  isPassword: true,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text('Continue'),
                        ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      context.goNamed('signup');
                    },
                    child: const Text('Create a new account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
