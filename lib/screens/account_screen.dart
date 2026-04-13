import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../theme/app_background.dart';
import '../theme/theme_controller.dart' show AppThemeController;
import '../utils/journal_streak_util.dart';
import '../route/app_routes.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;

  String displayName = '';
  String email = '';
  int currentStreak = 0;
  int longestStreak = 0;
  bool notificationsEnabled = true;
  bool isLoading = true;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open link')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = user?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final streakData = await JournalStreakUtil.getJournalStreak(uid);

    setState(() {
      displayName =
          userDoc.data()?['displayName'] ?? user?.displayName ?? 'User';
      email = user?.email ?? '';
      notificationsEnabled = userDoc.data()?['notificationsEnabled'] ?? true;
      currentStreak = streakData['currentStreak'] ?? 0;
      longestStreak = streakData['longestStreak'] ?? 0;
      isLoading = false;
    });
  }

  Widget _section(String title, Widget child) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _softGroup(List<Widget> children) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: color ?? colors.onSurface),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.onSurface.withOpacity(0.5),
                )
              : null),
      onTap: onTap,
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: displayName);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    await FirestoreService().updateDisplayName(result);
    await user?.updateDisplayName(result);

    setState(() => displayName = result);
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(
            icon: LucideIcons.monitor,
            title: 'System',
            onTap: () {
              AppThemeController.setTheme(ThemeMode.system);
              context.pop();
            },
          ),
          _tile(
            icon: LucideIcons.sun,
            title: 'Light',
            onTap: () {
              AppThemeController.setTheme(ThemeMode.light);
              context.pop();
            },
          ),
          _tile(
            icon: LucideIcons.moon,
            title: 'Dark',
            onTap: () {
              AppThemeController.setTheme(ThemeMode.dark);
              context.pop();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeController,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                  children: [
                    // PROFILE HEADER
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colors.primary.withOpacity(0.15),
                          child: Icon(LucideIcons.user, color: colors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.edit2,
                                      size: 16,
                                    ),
                                    onPressed: _editName,
                                  ),
                                ],
                              ),
                              Text(
                                email,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // PROGRESS
                    _section(
                      'Progress',
                      _softGroup([
                        _tile(
                          icon: LucideIcons.flame,
                          title: 'Current journal streak',
                          subtitle: '$currentStreak days',
                        ),
                        _tile(
                          icon: LucideIcons.award,
                          title: 'Longest streak',
                          subtitle: '$longestStreak days',
                        ),
                      ]),
                    ),

                    // PREFERENCES
                    _section(
                      'Preferences',
                      _softGroup([
                        _tile(
                          icon: LucideIcons.moon,
                          title: 'Theme',
                          subtitle: 'System / Light / Dark',
                          onTap: _showThemeSelector,
                        ),

                        // ✅ NOTIFICATION MANAGEMENT
                        _tile(
                          icon: LucideIcons.bell,
                          title: 'Notifications',
                          subtitle: notificationsEnabled
                              ? 'Enabled with smart scheduling'
                              : 'Disabled',
                          trailing: Switch(
                            value: notificationsEnabled,
                            onChanged: (val) async {
                              setState(() => notificationsEnabled = val);

                              final notificationService = NotificationService();

                              if (val) {
                                // Re-enable notifications
                                final granted = await notificationService
                                    .requestPermissions();

                                if (granted) {
                                  // Fetch user's journal reminder preference
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(user!.uid)
                                      .get();

                                  final journalReminder =
                                      userDoc.data()?['journalReminder'] ??
                                      'Evening';

                                  // ✅ SCHEDULE ALL NOTIFICATIONS
                                  await notificationService
                                      .scheduleAllNotifications(
                                        journalReminder,
                                      );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ All notifications enabled with smart features',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() => notificationsEnabled = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '⚠️ Please enable notifications in system settings',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Disable notifications
                                await notificationService.cancelAll();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '🔕 Notifications disabled',
                                      ),
                                    ),
                                  );
                                }
                              }

                              // Update Firestore
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .update({'notificationsEnabled': val});
                            },
                          ),
                        ),

                        // ✅ TEST NOTIFICATION (DEBUG ONLY)
                        if (kDebugMode)
                          _tile(
                            icon: LucideIcons.bellRing,
                            title: 'Test Notification',
                            subtitle: 'Send a test notification now',
                            onTap: () async {
                              await NotificationService()
                                  .showTestNotification();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📬 Test notification sent!'),
                                  ),
                                );
                              }
                            },
                          ),

                        // ✅ DEBUG: SHOW PENDING NOTIFICATIONS
                        if (kDebugMode)
                          _tile(
                            icon: LucideIcons.listChecks,
                            title: 'View Scheduled',
                            subtitle: 'See all pending notifications',
                            onTap: () async {
                              final pending = await NotificationService()
                                  .getPendingNotifications();
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text(
                                      'Scheduled Notifications',
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: pending.isEmpty
                                            ? [
                                                const Text(
                                                  'No pending notifications',
                                                ),
                                              ]
                                            : pending
                                                  .map(
                                                    (n) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      child: Text(
                                                        'ID ${n.id}: ${n.title}\n${n.body}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => context.pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),

                        // ✅ DEBUG: RESCHEDULE NOW
                        if (kDebugMode)
                          _tile(
                            icon: LucideIcons.refreshCw,
                            title: 'Reschedule Notifications',
                            subtitle: 'Force reschedule all notifications',
                            onTap: () async {
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .get();

                              final journalReminder =
                                  userDoc.data()?['journalReminder'] ??
                                  'Evening';

                              await NotificationService()
                                  .scheduleAllNotifications(journalReminder);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '✅ Notifications rescheduled!',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ]),
                    ),

                    // ABOUT
                    _section(
                      'About',
                      _softGroup([
                        _tile(
                          icon: LucideIcons.lock,
                          title: 'Privacy Policy',
                          onTap: () {
                            _openUrl(
                              'https://www.mindur.app/privacy-policy.html',
                            );
                          },
                        ),

                        _tile(
                          icon: LucideIcons.fileText,
                          title: 'Terms of Service',
                          onTap: () {
                            _openUrl(
                              'https://www.mindur.app/terms-of-service.html',
                            );
                          },
                        ),

                        _tile(
                          icon: LucideIcons.mail,
                          title: 'Contact Support',
                          subtitle: 'support@mindur.app',
                          onTap: () {
                            _openUrl('https://www.mindur.app/contact.html');
                          },
                        ),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (_, snap) {
                            if (!snap.hasData) {
                              return const SizedBox.shrink();
                            }
                            return _tile(
                              icon: LucideIcons.info,
                              title: 'App Version',
                              subtitle:
                                  '${snap.data!.version} (${snap.data!.buildNumber})',
                            );
                          },
                        ),
                      ]),
                    ),

                    // ACCOUNT
                    _section(
                      'Account',
                      _softGroup([
                        _tile(
                          icon: LucideIcons.logOut,
                          title: 'Log out',
                          onTap: () async {
                            // ✅ LOG SESSION END BEFORE LOGOUT

                            await FirebaseAuth.instance.signOut();

                            // ✅ CLEAR USER ID
                            await AnalyticsService().setUserId(null);

                            if (mounted) context.go('/login');
                          },
                        ),
                        _tile(
                          icon: LucideIcons.trash2,
                          title: 'Delete account',
                          color: colors.error,
                          onTap: () => _showDeleteAccountDialog(),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── DELETE ACCOUNT ────────────────────────────────────────────────────────

  /// Step 1 – Confirm with name or "delete" typed
  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();
    final scaffoldCtx = context; // capture scaffold context before dialog opens

    showDialog<void>(
      context: scaffoldCtx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        bool isProcessing = false;
        String? errorText;

        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            title: const Text('Delete Account?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will permanently delete your account and ALL your data. '
                    'This action cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    enabled: !isProcessing,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type your name or "delete"',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final input =
                            confirmController.text.trim().toLowerCase();
                        final nameMatch = user?.displayName
                            ?.trim()
                            .toLowerCase();

                        if (input.isEmpty ||
                            (input != 'delete' && input != nameMatch)) {
                          setDialogState(
                            () => errorText =
                                'Type your name or "delete" to confirm',
                          );
                          return;
                        }

                        setDialogState(() {
                          isProcessing = true;
                          errorText = null;
                        });

                        // Close step-1 dialog and move to re-auth step
                        Navigator.of(dialogCtx).pop();

                        if (scaffoldCtx.mounted) {
                          _showReauthAndDeleteDialog(scaffoldCtx);
                        }
                      },
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Theme.of(scaffoldCtx).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Step 2 – Re-authenticate then delete everything
  void _showReauthAndDeleteDialog(BuildContext scaffoldCtx) {
    final passwordController = TextEditingController();

    showDialog<void>(
      context: scaffoldCtx,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isDeleting = false;
        String? errorText;

        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            title: const Text('Confirm your password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For security, please enter your password to permanently delete your account.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    enabled: !isDeleting,
                    autofocus: true,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      errorText: errorText,
                    ),
                  ),
                  if (isDeleting) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Deleting account…'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isDeleting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        final password = passwordController.text;
                        if (password.isEmpty) {
                          setDialogState(
                            () => errorText = 'Please enter your password',
                          );
                          return;
                        }

                        setDialogState(() {
                          isDeleting = true;
                          errorText = null;
                        });

                        // Set flag BEFORE any async work so the router
                        // redirect is suppressed for the entire operation.
                        AppRoutes.isDeletingAccount = true;

                        try {
                          final currentUser =
                              FirebaseAuth.instance.currentUser;
                          if (currentUser == null) {
                            throw Exception('No authenticated user found.');
                          }

                          // ── 1. Re-authenticate ──────────────────────────
                          final credential = EmailAuthProvider.credential(
                            email: currentUser.email!,
                            password: password,
                          );
                          await currentUser
                              .reauthenticateWithCredential(credential);

                          // ── 2. Delete Firestore data ────────────────────
                          final uid = currentUser.uid;
                          final db = FirebaseFirestore.instance;
                          final userRef =
                              db.collection('users').doc(uid);

                          // Top-level subcollections
                          const simpleCollections = [
                            'journals',
                            'habits',
                            'foodlogging',
                            'workouts',
                            'badges',
                            'notification_analytics',
                            'ai_profile',
                          ];

                          for (final col in simpleCollections) {
                            final snap =
                                await userRef.collection(col).get();
                            for (final doc in snap.docs) {
                              await doc.reference.delete();
                            }
                          }

                          // ai_sessions has a nested messages sub-collection
                          final sessions =
                              await userRef.collection('ai_sessions').get();
                          for (final session in sessions.docs) {
                            final messages = await session.reference
                                .collection('messages')
                                .get();
                            for (final msg in messages.docs) {
                              await msg.reference.delete();
                            }
                            await session.reference.delete();
                          }

                          // Delete the root user document
                          await userRef.delete();

                          // ── 3. Delete Firebase Auth user ────────────────
                          await currentUser.delete();

                          // ── 4. Clear analytics & sign out ──────────────
                          await AnalyticsService().setUserId(null);

                          // ── 5. Navigate to login ────────────────────────
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (scaffoldCtx.mounted) {
                            scaffoldCtx.go('/login');
                          }
                        } on FirebaseAuthException catch (e) {
                          AppRoutes.isDeletingAccount = false;

                          String msg;
                          if (e.code == 'wrong-password' ||
                              e.code == 'invalid-credential') {
                            msg = 'Incorrect password. Please try again.';
                          } else if (e.code == 'too-many-requests') {
                            msg =
                                'Too many attempts. Please wait and try again.';
                          } else {
                            msg = e.message ?? 'Authentication failed.';
                          }

                          setDialogState(() {
                            isDeleting = false;
                            errorText = msg;
                          });
                        } catch (e) {
                          AppRoutes.isDeletingAccount = false;

                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (scaffoldCtx.mounted) {
                            ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to delete account: $e'),
                                backgroundColor:
                                    Theme.of(scaffoldCtx).colorScheme.error,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                        // NOTE: isDeletingAccount is intentionally NOT reset
                        // in a finally block here — it stays true until after
                        // navigation to /login completes, preventing the router
                        // redirect from firing mid-deletion. The flag is reset
                        // on error paths above, and is naturally irrelevant
                        // after the app navigates away (new session).
                      },
                child: Text(
                  'Delete My Account',
                  style: TextStyle(
                    color: Theme.of(scaffoldCtx).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
