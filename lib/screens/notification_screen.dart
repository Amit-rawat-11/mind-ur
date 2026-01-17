import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/app_background.dart';
import '../services/notification_helper.dart';

// ==========================================
// MODEL (Local for this screen)
// ==========================================
enum NotificationType {
  reminder,
  streak,
  achievement,
  summary,
  info,
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    NotificationType type;
    final typeStr = map['type'] ?? 'info';
    
    if (typeStr == 'reminder') type = NotificationType.reminder;
    else if (typeStr == 'streak') type = NotificationType.streak;
    else if (typeStr == 'achievement') type = NotificationType.achievement;
    else if (typeStr == 'summary') type = NotificationType.summary;
    else type = NotificationType.info;

    return NotificationItem(
      id: map['id'],
      title: map['title'] ?? 'Notification',
      body: map['body'] ?? '',
      timestamp: map['timestamp'] ?? DateTime.now(),
      type: type,
      isRead: map['isRead'] ?? true, 
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ==========================================
  // STATE
  // ==========================================
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Reminders',
    'Streaks',
    'Achievements',
    'Summary'
  ];

  late Future<List<NotificationItem>> _activityFeedFuture;
  List<NotificationItem> _allNotifications = [];
  List<NotificationItem> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _activityFeedFuture = _fetchActivityFeed();
  }

  Future<List<NotificationItem>> _fetchActivityFeed() async {
    final rawData = await NotificationHelper.getActivityFeed();
    final items = rawData.map((e) => NotificationItem.fromMap(e)).toList();
    
    // Sort logic handled in helper, but good to be safe
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Update local state for filtering
    setState(() {
      _allNotifications = items;
      _applyFilter();
    });
    
    return items;
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredNotifications = List.from(_allNotifications);
      } else {
        final typeMap = {
          'Reminders': NotificationType.reminder,
          'Streaks': NotificationType.streak,
          'Achievements': NotificationType.achievement,
          'Summary': NotificationType.summary,
        };
        final targetType = typeMap[_selectedFilter];
        _filteredNotifications = _allNotifications
            .where((n) => n.type == targetType)
            .toList();
      }
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotifications[index].isRead = true;
        _applyFilter();
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _allNotifications.removeWhere((n) => n.id == id);
      _applyFilter();
    });
    // Note: This only deletes locally from the feed view, not from firestore history in this implementation
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Activity',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? MindurColors.darkTextPrimary : MindurColors.lightTextPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? MindurColors.darkTextSecondary : MindurColors.lightTextSecondary,
              ),
              onPressed: () {
                setState(() {
                  _refreshData();
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(isDark),
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: _activityFeedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: MindurColors.primary,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(isDark, isGlobalEmpty: true);
                  }
                  
                  // Use _filteredNotifications which is updated in _applyFilter
                  if (_filteredNotifications.isEmpty) {
                    return _buildEmptyState(isDark, isGlobalEmpty: false);
                  }

                  return _buildNotificationList(isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter();
                });
              }
            },
            
            // Custom Styling to match Mind-ur
            backgroundColor: isDark 
                ? MindurColors.darkSurfaceContainerHigh 
                : MindurColors.lightSurfaceContainerHigh,
            selectedColor: MindurColors.primary,
            labelStyle: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? MindurColors.onPrimary
                  : (isDark ? MindurColors.darkTextSecondary : MindurColors.lightTextSecondary),
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];
        return _buildNotificationCard(notification, isDark);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem item, bool isDark) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: MindurColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(item.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? MindurColors.darkSurfaceContainerHigh 
                : MindurColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
            border: item.isRead 
                ? null 
                // Only show border highlight for unread items if desired, otherwise cleaner look
                : Border.all(color: MindurColors.primary.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(item.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                                color: isDark 
                                    ? MindurColors.darkTextPrimary 
                                    : MindurColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Optional: Indicator for unread
                          /*
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: MindurColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          */
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark 
                              ? MindurColors.darkTextSecondary 
                              : MindurColors.lightTextSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(item.timestamp),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark 
                              ? MindurColors.darkTextMuted 
                              : MindurColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.streak:
        iconData = Icons.local_fire_department_rounded;
        color = const Color(0xFFFF9F43); // Orange
        break;
      case NotificationType.achievement:
        iconData = Icons.emoji_events_rounded;
        color = const Color(0xFFFFC312); // Gold
        break;
      case NotificationType.summary:
        iconData = Icons.analytics_rounded;
        color = MindurColors.info; // Blue
        break;
      case NotificationType.reminder:
      default:
        iconData = Icons.notifications_active_rounded;
        color = MindurColors.primary; // Mint
        break;
    }

    return div(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: color, size: 20),
      ),
    );
  }
  
  // Helper to allow generic container usage if needed, but here just standardizing
  Widget div({required Widget child}) => child;

  Widget _buildEmptyState(bool isDark, {required bool isGlobalEmpty}) {
    IconData icon;
    String title;
    String message;

    if (isGlobalEmpty) {
       // Truly no data at all
      icon = Icons.notifications_off_rounded;
      title = 'No Activity Yet';
      message = 'Start using the app to see your activity here.';
    } else if (_selectedFilter == 'All') {
      icon = Icons.done_all_rounded;
      title = 'All caught up!';
      message = 'You have no notifications right now.';
    } else {
      icon = Icons.filter_list_off_rounded;
      title = 'No $_selectedFilter';
      message = 'You have no $_selectedFilter activity.';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark 
                  ? MindurColors.darkSurfaceContainerHigh.withOpacity(0.5) 
                  : MindurColors.lightSurfaceContainerHigh.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: isDark ? MindurColors.darkTextMuted : MindurColors.lightTextDisabled,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? MindurColors.darkTextPrimary : MindurColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? MindurColors.darkTextSecondary : MindurColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
