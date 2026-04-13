import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';
import '../constant/datetime.dart';
import '../models/journal.dart';
import '../services/firebase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JournalViewScreen
// ─────────────────────────────────────────────────────────────────────────────

class JournalViewScreen extends StatefulWidget {
  final String documentId;

  const JournalViewScreen({super.key, required this.documentId});

  @override
  State<JournalViewScreen> createState() => _JournalViewScreenState();
}

class _JournalViewScreenState extends State<JournalViewScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();

  JournalEntry? _entry;
  bool _loading = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _loadJournal();
  }

  Future<void> _loadJournal() async {
    final entry = await _firestoreService.getJournalEntry(widget.documentId);
    if (mounted) {
      setState(() {
        _entry = entry;
        _loading = false;
      });
      _animController.forward();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int get _wordCount {
    final text = _entry?.content.trim() ?? '';
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  String get _formattedDate {
    final ts = _entry?.timestamp;
    if (ts == null) return '';
    return '${_monthName(ts.month)} ${ts.day}, ${ts.year}';
  }

  String get _dayName {
    final ts = _entry?.timestamp;
    if (ts == null) return '';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[ts.weekday - 1];
  }

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];

  // ── Build ─────────────────────────────────────────────────────────────────

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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _entry == null
              ? _buildNotFound(theme)
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),

                        // ── Back + Day ──────────────────────────────
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
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
                              _dayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // ── Date ────────────────────────────────────
                        Text(
                          _formattedDate,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Stat badges ─────────────────────────────
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _badge(
                              context,
                              "📖 Reading",
                              colors.primary.withValues(alpha: 0.12),
                            ),
                            _badge(
                              context,
                              "$_wordCount words",
                              colors.primary.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Paper card ──────────────────────────────
                        Expanded(
                          child: Stack(
                            children: [
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Title ─────────────────────
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
                                              child: Text(
                                                _entry!.title,
                                                style: theme
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
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

                                      // ── Ruled content area ────────
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            // Notebook lines + margin
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: _NotebookPainter(
                                                  lineColor: lineColor,
                                                  marginColor: marginColor,
                                                ),
                                              ),
                                            ),

                                            // Scrollable content
                                            Positioned.fill(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 52,
                                                  right: 18,
                                                  top: 6,
                                                  bottom: 60,
                                                ),
                                                child: SingleChildScrollView(
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Text(
                                                      _entry!.content,
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            height: 1.75,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Word count — bottom right
                                            Positioned(
                                              bottom: 12,
                                              right: 16,
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ── Edit FAB ───────────────────────────
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: FloatingActionButton.extended(
                                  onPressed: () async {
                                    await context.pushNamed(
                                      'journal-edit',
                                      pathParameters: {'id': widget.documentId},
                                    );
                                    // Reload in case user saved changes
                                    setState(() => _loading = true);
                                    _loadJournal();
                                  },
                                  elevation: 6,
                                  label: const Text("Edit Entry"),
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.find_in_page_outlined, size: 48, color: theme.hintColor),
          const SizedBox(height: 12),
          Text(
            "Entry not found",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Go back"),
          ),
        ],
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

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notebook Painter  (local copy — same as JournalEditScreen)
// ─────────────────────────────────────────────────────────────────────────────

class _NotebookPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double lineSpacing;
  final double marginOffset;
  final List<Offset> _grain;

  _NotebookPainter({
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
  bool shouldRepaint(_NotebookPainter old) =>
      old.lineColor != lineColor || old.marginColor != marginColor;
}
