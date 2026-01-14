import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mindur/screens/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../theme/app_background.dart';
import '../theme/theme_controller.dart' show AppThemeController;
import '../utils/journal_streak_util.dart';

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
        color: colors.onSurface.withOpacity(0.035),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy policy coming soon'),
                              ),
                            );
                          },
                        ),
                        _tile(
                          icon: LucideIcons.fileText,
                          title: 'Terms of Service',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Terms of service coming soon'),
                              ),
                            );
                          },
                        ),
                        _tile(
                          icon: LucideIcons.mail,
                          title: 'Contact Support',
                          subtitle: 'support@mindur.app',
                          onTap: () {},
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
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Account?'),
                                content: const Text(
                                  'This will permanently delete all your data. This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      FirebaseAuth.instance.currentUser
                                          ?.delete();
                                      context.go('/login');
                                    },
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: colors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
