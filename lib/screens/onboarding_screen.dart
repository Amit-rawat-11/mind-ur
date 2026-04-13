import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for each onboarding page
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingData {
  final String heading;
  final String subtext;
  final _PageType type;

  const _OnboardingData({
    required this.heading,
    required this.subtext,
    required this.type,
  });
}

enum _PageType { hook, relatable, action }

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      heading: 'Stop starting over.',
      subtext: 'You don\'t need motivation.\nYou need consistency.',
      type: _PageType.hook,
    ),
    _OnboardingData(
      heading: 'You restart every week.',
      subtext: 'Miss one day → feel bad\n→ quit → repeat',
      type: _PageType.relatable,
    ),
    _OnboardingData(
      heading: 'Start small.\nStay consistent.',
      subtext: '',
      type: _PageType.action,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── Subtle background gradient blob ──────────────────────────────
          Positioned(
            top: -120,
            left: -80,
            child: _GradientBlob(
              color: MindurColors.sageMint.withAlpha(30),
              size: 380,
            ),
          ),
          Positioned(
            bottom: -60,
            right: -100,
            child: _GradientBlob(
              color: MindurColors.sageMintDeep.withAlpha(20),
              size: 300,
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) {
                      return _OnboardingPage(
                        data: _pages[i],
                        isActive: _currentPage == i,
                        onAction: _goNext,
                      );
                    },
                  ),
                ),

                // ── Dots indicator ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: MindurColors.sageMint,
                      dotColor: Colors.white.withAlpha(40),
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 5,
                      spacing: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual page — owns its own animation controller
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage extends StatefulWidget {
  final _OnboardingData data;
  final bool isActive;
  final VoidCallback onAction;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.onAction,
  });

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Per-line staggered fade+slide
  late final Animation<double> _line1Opacity;
  late final Animation<Offset> _line1Slide;
  late final Animation<double> _line2Opacity;
  late final Animation<Offset> _line2Slide;
  late final Animation<double> _visualOpacity;
  late final Animation<double> _btnOpacity;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _line1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );
    _line1Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic)),
    );

    _line2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _line2Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)),
    );

    _visualOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.75, curve: Curves.easeOut)),
    );

    _btnOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    _btnScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack)),
    );

    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_OnboardingPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ctrl.forward(from: 0);
    } else if (!widget.isActive && old.isActive) {
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          // ── Heading ───────────────────────────────────────────────────────
          FadeTransition(
            opacity: _line1Opacity,
            child: SlideTransition(
              position: _line1Slide,
              child: Text(
                widget.data.heading,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),

          if (widget.data.subtext.isNotEmpty) ...[
            const SizedBox(height: 20),

            // ── Subtext ───────────────────────────────────────────────────
            FadeTransition(
              opacity: _line2Opacity,
              child: SlideTransition(
                position: _line2Slide,
                child: Text(
                  widget.data.subtext,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(140),
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 52),

          // ── Visual element (page-specific) ────────────────────────────
          FadeTransition(
            opacity: _visualOpacity,
            child: Center(child: _buildVisual()),
          ),

          const Spacer(flex: 3),

          // ── CTA button (only on last page) ────────────────────────────
          if (widget.data.type == _PageType.action)
            FadeTransition(
              opacity: _btnOpacity,
              child: ScaleTransition(
                scale: _btnScale,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PulsingButton(onTap: widget.onAction),
                ),
              ),
            ),

          if (widget.data.type != _PageType.action) const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildVisual() {
    switch (widget.data.type) {
      case _PageType.hook:
        return const _HookVisual();
      case _PageType.relatable:
        return const _StreakResetVisual();
      case _PageType.action:
        return const _ActionVisual();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 1 Visual – simple minimal line mark
// ─────────────────────────────────────────────────────────────────────────────
class _HookVisual extends StatelessWidget {
  const _HookVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(18), width: 1),
        color: Colors.white.withAlpha(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(width: 160, color: MindurColors.sageMint, intensity: 1.0),
          _Bar(width: 120, color: MindurColors.sageMintSoft, intensity: 0.7),
          _Bar(width: 80, color: Colors.white, intensity: 0.25),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final Color color;
  final double intensity;

  const _Bar({required this.width, required this.color, required this.intensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: color.withAlpha((255 * intensity).round()),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 2 Visual – streak dots that reset with animation
// ─────────────────────────────────────────────────────────────────────────────
class _StreakResetVisual extends StatefulWidget {
  const _StreakResetVisual();

  @override
  State<_StreakResetVisual> createState() => _StreakResetVisualState();
}

class _StreakResetVisualState extends State<_StreakResetVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // We animate through: build-up → pause → reset → pause → repeat
  // Total cycle = 3 s
  int _filledCount = 0;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(_tick)
      ..repeat();
  }

  void _tick() {
    final t = _ctrl.value; // 0..1 over 3s

    // Phase 1 (0–0.5): fill dots one by one
    if (t < 0.5) {
      final filled = (t / 0.5 * 7).floor().clamp(0, 7);
      if (mounted && filled != _filledCount && !_resetting) {
        setState(() => _filledCount = filled);
      }
    }
    // Phase 2 (0.5–0.6): hold
    // Phase 3 (0.6–0.95): reset
    else if (t >= 0.6 && t < 0.95) {
      if (!_resetting) setState(() => _resetting = true);
      final remaining = (7 - ((t - 0.6) / 0.35 * 7)).ceil().clamp(0, 7);
      if (mounted && remaining != _filledCount) {
        setState(() => _filledCount = remaining);
      }
    }
    // Phase 4 (0.95–1): reset to 0
    else if (t >= 0.95) {
      if (mounted && _filledCount != 0) {
        setState(() {
          _filledCount = 0;
          _resetting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) {
            final isFilled = i < _filledCount;
            final isLastFilled = i == _filledCount - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isLastFilled ? 22 : 18,
              height: isLastFilled ? 22 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (_resetting
                        ? MindurColors.error.withAlpha(200)
                        : MindurColors.sageMint)
                    : Colors.white.withAlpha(20),
                boxShadow: isFilled && !_resetting
                    ? [
                        BoxShadow(
                          color: MindurColors.sageMint.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        AnimatedOpacity(
          opacity: _resetting ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            'back to zero…',
            style: TextStyle(
              fontSize: 12,
              color: MindurColors.error.withAlpha(180),
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 3 Visual – a soft writing icon with glow
// ─────────────────────────────────────────────────────────────────────────────
class _ActionVisual extends StatelessWidget {
  const _ActionVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MindurColors.sageMint.withAlpha(22),
        boxShadow: [
          BoxShadow(
            color: MindurColors.sageMint.withAlpha(50),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
        border: Border.all(color: MindurColors.sageMint.withAlpha(60), width: 1),
      ),
      child: const Icon(
        Icons.edit_outlined,
        color: MindurColors.sageMint,
        size: 38,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing CTA button on screen 3
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingButton({required this.onTap});

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 6.0, end: 22.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: MindurColors.sageMint.withAlpha(100),
                    blurRadius: _glow.value,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MindurColors.sageMint,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 22),
                    SizedBox(width: 10),
                    Text('Start your first entry'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background decorative blob
// ─────────────────────────────────────────────────────────────────────────────
class _GradientBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GradientBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 6,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }
}