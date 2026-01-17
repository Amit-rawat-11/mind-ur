import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final void Function(String sessionId) onSessionTap;
  final Future<void> Function(String sessionId) onDeleteSession;

  const SessionDrawer({
    super.key,
    required this.sessions,
    required this.onSessionTap,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: Colors.black.withOpacity(0.3), // glass base (unchanged)
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Text(
                          "No sessions yet!",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return _buildSessionTile(
                            context,
                            session,
                            theme,
                            colorScheme,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4), // unchanged
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🕘 Session History",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your past sessions with Aurora",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    Map<String, dynamic> session,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    DateTime? createdAt;
    final rawCreatedAt = session['createdAt'];

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return Dismissible(
      key: Key(session['id'] ?? 'unknown'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colorScheme.error.withOpacity(0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(
              "Delete Session?",
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            content: Text(
              "This will permanently delete this session & messages.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "CANCEL",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "DELETE",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDeleteSession(session['id']),
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        title: Text(
          session['title'] ?? "Untitled",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          createdAt != null
              ? "Created ${DateFormat('MMM d, hh:mm a').format(createdAt)}"
              : "Created at unknown time",
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        onTap: () {
      
          Navigator.pop(context);
          onSessionTap(session['id']);
        },
      ),
    );
  }
}
