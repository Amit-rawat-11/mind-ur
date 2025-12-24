import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/input_textfield.dart';
import '../services/signup_service.dart';
import '../screens/login_screen.dart';
import 'personalization_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  bool isLoading = false;
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();

    confirmPassController.addListener(() {
      final pass = passwordController.text;
      final confirm = confirmPassController.text;

      setState(() {
        _passwordsMatch = confirm.isEmpty || pass == confirm;
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPassController.dispose();
    dateController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final confirmPass = confirmPassController.text;

    if (name.isEmpty) return 'Please enter your name.';
    if (email.isEmpty) return 'Please enter your email.';
    if (!email.contains('@')) return 'Please enter a valid email.';
    if (pass.isEmpty) return 'Please enter a password.';
    if (pass.length < 6) return 'Password must be at least 6 characters.';
    if (confirmPass.isEmpty) return 'Please confirm your password.';
    if (pass != confirmPass) return 'Passwords do not match.';
    return null;
  }

  Future<void> _handleSignup() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _showSnack(validationError, isError: true);
      return;
    }

    setState(() => isLoading = true);

    DateTime? parsedDob;
    if (dateController.text.trim().isNotEmpty) {
      try {
        parsedDob = DateFormat(
          'dd/MM/yyyy',
        ).parseStrict(dateController.text.trim());
      } catch (_) {
        _showSnack('Invalid date format', isError: true);
        setState(() => isLoading = false);
        return;
      }
    }

    final errorMessage = await SignupService().signUp(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      dob: parsedDob,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (errorMessage != null) {
      _showSnack(errorMessage, isError: true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalizationScreen()),
      );
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  Center(
                    child: SvgPicture.asset(
                      'assets/images/svg/signup.svg',
                      height: 220,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Create an account',
                    style: theme.textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'A few details to get started.',
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  InputTextfield(
                    autofillHints: const [AutofillHints.name],
                    labelText: 'Name',
                    controller: nameController,
                    isPassword: false,
                  ),

                  const SizedBox(height: 20),

                  InputTextfield(
                    labelText: 'Email',
                    controller: emailController,
                    isPassword: false,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                  ),

                  const SizedBox(height: 20),

                  InputTextfield(
                    autofillHints: const [AutofillHints.password],
                    labelText: 'Password',
                    controller: passwordController,
                    isPassword: true,
                  ),

                  const SizedBox(height: 20),

                  InputTextfield(
                    autofillHints: const [AutofillHints.password],
                    labelText: 'Confirm password',
                    controller: confirmPassController,
                    isPassword: true,
                    helperText: !_passwordsMatch
                        ? 'Passwords do not match yet'
                        : null,
                    errorText: !_passwordsMatch
                        ? ' '
                        : null, // triggers error border
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      labelText: 'Date of birth',
                      prefixIcon: Icon(
                        LucideIcons.calendar,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      suffixIcon: Icon(
                        LucideIcons.chevronDown,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSignup,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
