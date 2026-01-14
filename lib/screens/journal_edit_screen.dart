import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';
import '../constant/datetime.dart';
import '../models/journal.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';

class JournalEditScreen extends StatefulWidget {
  final String? documentId;

  const JournalEditScreen({super.key, this.documentId});

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  final firestoreService = FirestoreService();

  String? titleError;
  String? contentError;

  bool get isEditing => widget.documentId != null;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    contentController = TextEditingController();

    if (isEditing) {
      _loadJournal();
    }
  }

  Future<void> _loadJournal() async {
    final entry = await firestoreService.getJournalEntry(widget.documentId!);
    if (entry != null) {
      titleController.text = entry.title;
      contentController.text = entry.content;
    }
  }

  void saveEntry() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    setState(() {
      titleError = title.isEmpty ? "Title can't be empty" : null;
      contentError = content.isEmpty ? "Content can't be empty" : null;
    });

    if (titleError != null || contentError != null) return;

    final entry = JournalEntry(
      title: title,
      content: content,
      timestamp: DateTime.now(),
    );

    if (isEditing) {
      await firestoreService.updateJournalEntry(widget.documentId!, entry);

      // ✅ LOG JOURNAL EDIT
      await AnalyticsService().logJournalEdited(entryId: widget.documentId!);
    } else {
      await firestoreService.addJournalEntry(entry);

      // ✅ LOG JOURNAL CREATION
      final wordCount = content
          .split(' ')
          .where((word) => word.isNotEmpty)
          .length;
      final hour = DateTime.now().hour;
      String timeOfDay;
      if (hour < 12) {
        timeOfDay = 'morning';
      } else if (hour < 17) {
        timeOfDay = 'afternoon';
      } else if (hour < 21) {
        timeOfDay = 'evening';
      } else {
        timeOfDay = 'night';
      }

      await AnalyticsService().logJournalCreated(
        wordCount: wordCount,
        timeOfDay: timeOfDay,
      );
    }

    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Saved successfully")),
          ],
        ),
        backgroundColor: colors.secondary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    context.pop();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.error, width: 1.5),
    );

    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outline),
    );

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(TimeUtils.formattedDate),
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: saveEntry),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title field
                TextField(
                  controller: titleController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Heading',
                    labelStyle: theme.textTheme.bodyMedium,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: normalBorder,
                    focusedBorder: normalBorder.copyWith(
                      borderSide: BorderSide(color: colors.primary),
                    ),
                    errorText: titleError,
                    errorBorder: errorBorder,
                    focusedErrorBorder: errorBorder,
                  ),
                ),
                const SizedBox(height: 20),

                // Content field
                TextField(
                  controller: contentController,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: 'Journal Entry',
                    labelStyle: theme.textTheme.bodyMedium,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: normalBorder,
                    focusedBorder: normalBorder.copyWith(
                      borderSide: BorderSide(color: colors.primary),
                    ),
                    errorText: contentError,
                    errorBorder: errorBorder,
                    focusedErrorBorder: errorBorder,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: MediaQuery.of(context).size.width * 0.12,
                  child: ElevatedButton(
                    onPressed: saveEntry,
                    child: const Text('Save'),
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
