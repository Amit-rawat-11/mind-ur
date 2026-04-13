import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/input_textfield.dart';
import '../services/analytics_service.dart';
import '../services/signup_service.dart';

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

      if (!mounted) return;
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

  /// Shows a dialog asking for an email and sends a Firebase password-reset link.
  void _showForgotPasswordDialog() {
    // Pre-fill with whatever the user already typed in the email field
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    final scaffoldCtx = context;

    showDialog<void>(
      context: scaffoldCtx,
      builder: (dialogCtx) {
        bool isSending = false;
        String? errorText;

        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            title: const Text('Reset password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your account email and we\'ll send you a link to reset your password.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  enabled: !isSending,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: const Icon(Icons.mail_outline),
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isSending ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();

                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(
                            () => errorText = 'Please enter a valid email',
                          );
                          return;
                        }

                        setDialogState(() {
                          isSending = true;
                          errorText = null;
                        });

                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: email);

                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (scaffoldCtx.mounted) {
                            ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Reset link sent to $email — check your inbox.',
                                ),
                                duration: const Duration(seconds: 5),
                                backgroundColor:
                                    Theme.of(scaffoldCtx).colorScheme.primary,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          String msg;
                          switch (e.code) {
                            case 'user-not-found':
                              msg = 'No account found with this email.';
                            case 'invalid-email':
                              msg = 'The email address is not valid.';
                            case 'too-many-requests':
                              msg = 'Too many attempts. Please wait a moment.';
                            default:
                              msg = e.message ?? 'Something went wrong.';
                          }
                          setDialogState(() {
                            isSending = false;
                            errorText = msg;
                          });
                        } catch (_) {
                          setDialogState(() {
                            isSending = false;
                            errorText = 'Failed to send reset email.';
                          });
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send link'),
              ),
            ],
          ),
        );
      },
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

                // ── Forgot password link ────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
