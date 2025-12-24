import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/recent_entry_card.dart';
import 'journal_edit_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<QueryDocumentSnapshot>> _getUserJournalEntries() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('journals')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs;
  }

  Future<void> _deleteJournalEntry(String entryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('journals')
        .doc(entryId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Journals"),
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JournalEditScreen(),
                  ),
                );
                setState(() {});
              },
            ),
          ],
        ),
        body: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _getUserJournalEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
      
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }
      
            final entries = snapshot.data ?? [];
      
            // Demo journals
            if (entries.isEmpty) {
              final demoJournals = [
                {
                  'title': 'Welcome to MIND-UR ✨',
                  'content':
                      'Tap the + button above to add your first journal entry.',
                },
                {
                  'title': 'Edit Your Journals 📝',
                  'content':
                      'Tap on any journal card to edit or view the details.',
                },
              ];
      
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: demoJournals.length,
                itemBuilder: (context, index) {
                  final demo = demoJournals[index];
                  return RecentEntryCard(
                    text: demo['title']!,
                    subtitle: demo['content']!,
                    width: double.infinity,
                    height: 200,
                  );
                },
              );
            }
      
            // Actual journals
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final title = entry['title'] ?? 'No Title';
                final content = entry['content'] ?? 'No Content';
      
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Slidable(
                    key: ValueKey(entry.id),
                    endActionPane: ActionPane(
                      motion: const BehindMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            await _deleteJournalEntry(entry.id);
                            setState(() {});
                          },
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                          borderRadius: BorderRadius.circular(12),
                          icon: LucideIcons.trash,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                JournalEditScreen(documentId: entry.id),
                          ),
                        );
                        setState(() {});
                      },
                      child: RecentEntryCard(
                        text: title,
                        subtitle: content,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
