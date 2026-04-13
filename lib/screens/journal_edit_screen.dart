import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';
import '../constant/datetime.dart';
import '../models/journal.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Save State
// ─────────────────────────────────────────────────────────────────────────────

enum _SaveState { idle, editing, saving, saved }

// ─────────────────────────────────────────────────────────────────────────────
//  JournalEditScreen
// ─────────────────────────────────────────────────────────────────────────────

class JournalEditScreen extends StatefulWidget {
  final String? documentId;

  const JournalEditScreen({super.key, this.documentId});

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocus;
  late final FocusNode _contentFocus;

  final _firestoreService = FirestoreService();

  String? _titleError;
  String? _contentError;
  bool _isSaving = false;

  int _wordCount = 0;
  int _writingMinutes = 0;
  Timer? _writingTimer;
  _SaveState _saveState = _SaveState.idle;
  bool _hasUnsavedChanges = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  bool get _isEditing => widget.documentId != null;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _titleController.addListener(_onAnyChange);
    _contentController.addListener(_onTextChanged);

    if (_isEditing) {
      _loadJournal();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  // ── Firebase load ─────────────────────────────────────────────────────────

  Future<void> _loadJournal() async {
    final entry = await _firestoreService.getJournalEntry(widget.documentId!);
    if (entry != null && mounted) {
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _syncWordCount(entry.content);
      setState(() => _hasUnsavedChanges = false);
    }
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void _onAnyChange() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  void _onTextChanged() {
    final text = _contentController.text.trim();

    if (text.isNotEmpty && _writingTimer == null) {
      _writingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() => _writingMinutes++);
      });
    }

    if (text.isEmpty && _writingTimer != null) {
      _writingTimer?.cancel();
      _writingTimer = null;
    }

    setState(() {
      _syncWordCount(text);
      _saveState = _SaveState.editing;
      _contentError = null;
      _hasUnsavedChanges = true;
    });
  }

  void _syncWordCount(String text) {
    _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  // ── Unsaved changes guard ─────────────────────────────────────────────────

  Future<bool> _onPopInvoked() async {
    if (!_hasUnsavedChanges || _saveState == _SaveState.saved) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Discard changes?"),
        content: const Text(
          "You have unsaved changes. If you go back now, they'll be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Keep writing"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Discard"),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? "Title can't be empty" : null;
      _contentError = content.isEmpty ? "Content can't be empty" : null;
    });

    if (_titleError != null || _contentError != null) return;

    setState(() {
      _isSaving = true;
      _saveState = _SaveState.saving;
    });

    try {
      final entry = JournalEntry(
        title: title,
        content: content,
        timestamp: DateTime.now(),
      );

      if (_isEditing) {
        await _firestoreService.updateJournalEntry(widget.documentId!, entry);
        await AnalyticsService().logJournalEdited(entryId: widget.documentId!);
      } else {
        await _firestoreService.addJournalEntry(entry);

        // 🆕 Mark first journal entry done so routing skips onboarding redirect
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'firstJournalDone': true}, SetOptions(merge: true));
        }

        final wc = content.split(' ').where((w) => w.isNotEmpty).length;
        final hour = DateTime.now().hour;
        final timeOfDay = hour < 12
            ? 'morning'
            : hour < 17
            ? 'afternoon'
            : hour < 21
            ? 'evening'
            : 'night';

        await AnalyticsService().logJournalCreated(
          wordCount: wc,
          timeOfDay: timeOfDay,
        );
      }

      if (!mounted) return;

      setState(() {
        _saveState = _SaveState.saved;
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text("Saved successfully")),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _writingTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    final paperColor = isDark
        ? const Color(0xff1c1c1e)
        : const Color(0xfffaf9f6);

    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xffcfe0f5);

    final marginColor = isDark
        ? Colors.redAccent.withValues(alpha: 0.25)
        : Colors.redAccent.withValues(alpha: 0.35);

    // ✅ Completely invisible input decoration — no border, no fill,
    //    no color change on focus. Feels like writing directly on paper.
    const cleanInput = InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      filled: false,
      contentPadding: EdgeInsets.zero,
    );

    return AppBackground(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final canLeave = await _onPopInvoked();
          if (canLeave && mounted) {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/');
            }
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,

            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),

                      // ── Back + Day ────────────────────────────────────
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final router = GoRouter.of(context);
                              final canLeave = await _onPopInvoked();
                              if (canLeave && mounted) {
                                if (router.canPop()) {
                                  router.pop();
                                } else {
                                  router.go('/');
                                }
                              }
                            },
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: theme.hintColor,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            TimeUtils.dayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ── Date ──────────────────────────────────────────
                      Text(
                        TimeUtils.formattedDate,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Stat badges ───────────────────────────────────
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _badge(
                            context,
                            _isEditing ? "✏️ Editing" : "🆕 New Entry",
                            colors.primary.withValues(alpha: 0.12),
                          ),
                          _badge(
                            context,
                            "$_wordCount words",
                            colors.primary.withValues(alpha: 0.12),
                          ),
                          _badge(
                            context,
                            "$_writingMinutes min",
                            Colors.teal.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Paper card — expands to fill remaining space ───
                      Expanded(
                        child: Stack(
                          children: [
                            // Paper card itself
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: paperColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(
                                      alpha: isDark ? 0.4 : 0.1,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Title ───────────────────────────
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        16,
                                        20,
                                        0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Left accent bar
                                          Container(
                                            width: 3,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: colors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: _titleController,
                                              focusNode: _titleFocus,
                                              maxLines: 1,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              onSubmitted: (_) =>
                                                  _contentFocus.requestFocus(),
                                              onChanged: (_) {
                                                if (_titleError != null) {
                                                  setState(
                                                    () => _titleError = null,
                                                  );
                                                }
                                              },
                                              decoration: cleanInput.copyWith(
                                                hintText:
                                                    "Give your entry a title",
                                                hintStyle: TextStyle(
                                                  color: theme.hintColor
                                                      .withValues(alpha: 0.45),
                                                ),
                                                errorText: _titleError,
                                              ),
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        top: 10,
                                      ),
                                      child: Divider(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        height: 1,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // ── Ruled content area ───────────────
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          // Notebook lines + margin
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: NotebookPainter(
                                                lineColor: lineColor,
                                                marginColor: marginColor,
                                              ),
                                            ),
                                          ),

                                          // Content text field
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 52,
                                              right: 18,
                                              top: 6,
                                              bottom: 16,
                                            ),
                                            child: TextField(
                                              controller: _contentController,
                                              focusNode: _contentFocus,
                                              maxLines: null,
                                              expands: true,
                                              textAlignVertical:
                                                  TextAlignVertical.top,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: cleanInput.copyWith(
                                                hintText: "Start writing...",
                                                hintStyle: TextStyle(
                                                  color: theme.hintColor
                                                      .withValues(alpha: 0.4),
                                                ),
                                                errorText: _contentError,
                                              ),
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(height: 1.75),
                                            ),
                                          ),

                                          // Word count — bottom-right of card
                                          Positioned(
                                            bottom: 12,
                                            right: 16,
                                            child: AnimatedOpacity(
                                              opacity: _wordCount > 0
                                                  ? 1.0
                                                  : 0.0,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Text(
                                                "$_wordCount words",
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: theme.hintColor
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ✅ FAB floating OVER the bottom of the paper
                            //    card — more writing space, looks integrated
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.extended(
                                onPressed: _isSaving ? null : _saveEntry,
                                elevation: 6,
                                label: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isEditing ? "Update" : "Save Entry",
                                      ),
                                icon: _isSaving
                                    ? const SizedBox.shrink()
                                    : const Icon(Icons.check_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Save status ───────────────────────────────────
                      _SaveStatusRow(state: _saveState),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Save Status Row
// ─────────────────────────────────────────────────────────────────────────────

class _SaveStatusRow extends StatelessWidget {
  final _SaveState state;

  const _SaveStatusRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (IconData icon, Color color, String label) = switch (state) {
      _SaveState.idle => (
        Icons.edit_note_rounded,
        theme.hintColor,
        "Not saved yet",
      ),
      _SaveState.editing => (Icons.edit_rounded, Colors.orange, "Editing..."),
      _SaveState.saving => (
        Icons.cloud_upload_rounded,
        Colors.blue,
        "Saving...",
      ),
      _SaveState.saved => (
        Icons.check_circle_rounded,
        Colors.green,
        "Saved just now",
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notebook Painter
// ─────────────────────────────────────────────────────────────────────────────

class NotebookPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double lineSpacing;
  final double marginOffset;
  final List<Offset> _grain;

  NotebookPainter({
    required this.lineColor,
    required this.marginColor,
    this.lineSpacing = 30.0,
    this.marginOffset = 42.0,
  }) : _grain = List.generate(400, (_) {
         final r = Random();
         return Offset(r.nextDouble(), r.nextDouble());
       });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(marginOffset, 0),
      Offset(marginOffset, size.height),
      marginPaint,
    );

    final grainPaint = Paint()..color = Colors.grey.withValues(alpha: 0.04);

    for (final n in _grain) {
      canvas.drawCircle(
        Offset(n.dx * size.width, n.dy * size.height),
        0.7,
        grainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(NotebookPainter old) =>
      old.lineColor != lineColor || old.marginColor != marginColor;
}
