import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mindur/theme/app_background.dart';
import 'package:mindur/theme/colors.dart';
import 'package:vertical_weight_slider/vertical_weight_slider.dart';

import '../components/personalized_radio_input.dart';
import '../route/app_routes.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  String petSelection = '';
  String fitnessgoal = '';
  String appgoal = '';
  String journalreminder = '';
  bool _isLoading = false;

  late final WeightSliderController _weightController;
  late final WeightSliderController _weightGoalController;
  late final WeightSliderController _heightController;

  double weight = 60.0;
  double weightGoal = 60.0;
  double height = 165.0;

  bool _isHeightCm = true;
  int _heightFt = 5;
  int _heightIn = 5;

  @override
  void initState() {
    super.initState();

    _weightController = WeightSliderController(
      initialWeight: weight,
      minWeight: 40,
      interval: 0.5,
    );

    _weightGoalController = WeightSliderController(
      initialWeight: weightGoal,
      minWeight: 40,
      interval: 0.5,
    );

    _heightController = WeightSliderController(
      initialWeight: height,
      minWeight: 120,
      maxWeight: 220,
      interval: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _weightGoalController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage == 0 && (appgoal.isEmpty || fitnessgoal.isEmpty)) {
      _showError('Please select your goals to continue.');
      return;
    }
    if (_currentPage == 1 && petSelection.isEmpty) {
      _showError('Please choose a dashboard companion.');
      return;
    }
    if (_currentPage == 2 && journalreminder.isEmpty) {
      _showError('Please select a reminder preference.');
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage++);
    } else {
      _completePersonalization();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage--);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MindurColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _completePersonalization() async {
    setState(() => _isLoading = true);

    try {
      // ✅ FIX BUG #1: Save to Firestore FIRST — this is the critical write.
      // Everything else (notifications, analytics) is non-critical and runs
      // after, each wrapped in its own try/catch so they can NEVER skip this.
      double finalHeight = _isHeightCm
          ? height
          : ((_heightFt * 30.48) + (_heightIn * 2.54));

      await FirestoreService().saveUserPersonalization(
        petSelection: petSelection,
        fitnessGoal: fitnessgoal,
        appGoal: appgoal,
        journalReminder: journalreminder,
        height: finalHeight,
        currentWeight: weight,
        goalWeight: weightGoal,
      );

      // ✅ Notifications — isolated: failure here will NOT lose any data
      try {
        final notificationService = NotificationService();
        final permissionGranted = await notificationService.requestPermissions();

        if (permissionGranted) {
          await notificationService.scheduleAllNotifications(journalreminder);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Notifications disabled. You can enable them later.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Notification setup failed (non-critical): $e');
      }

      // ✅ Analytics — isolated: failure here will NOT lose any data
      try {
        await AnalyticsService().logPersonalizationCompleted(
          fitnessGoal: fitnessgoal,
          appGoal: appgoal,
          notificationTime: journalreminder,
        );
        await AnalyticsService().setUserProperties(
          fitnessGoal: fitnessgoal,
          appGoal: appgoal,
          notificationPreference: journalreminder,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Analytics failed (non-critical): $e');
      }

      if (mounted) context.go(AppRoutes.journalNew);
    } catch (e) {
      // ✅ FIX BUG #1: Catch the Firestore write failure and show a real error
      if (kDebugMode) debugPrint('❌ Personalization save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to save your preferences. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: List.generate(_totalPages, (index) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: index == _totalPages - 1 ? 0 : 8),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentPage 
                              ? MindurColors.sageMint 
                              : Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                    _buildPage4(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _isLoading ? null : _prevPage,
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white.withAlpha(160),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MindurColors.sageMint,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                            )
                          : Text(
                              _currentPage == _totalPages - 1 ? 'Finish' : 'Continue',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContainer(String title, String subtitle, Widget child) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withAlpha(140),
            ),
          ),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPage1() => _buildPageContainer(
    'Set Your Intentions',
    'What are you hoping to achieve with Mindur?',
    Column(
      children: [
        PersonalizedSelectionGroup<String>(
          question: "What's your main goal with this app?",
          groupValue: appgoal,
          onChanged: (value) => setState(() => appgoal = value ?? ''),
          options: const [
            SelectionOption(value: 'Journaling & self-reflection', title: 'Journaling & Reflection', subtitle: 'Clear your mind and track your thoughts.', icon: Icons.book_outlined),
            SelectionOption(value: 'Building habits & discipline', title: 'Habits & Discipline', subtitle: 'Build consistent routines and stick to them.', icon: Icons.loop_rounded),
            SelectionOption(value: 'Fitness & food tracking', title: 'Holistic Health', subtitle: 'Track your meals, fitness, and overall well-being.', icon: Icons.spa_outlined),
          ],
        ),
        const SizedBox(height: 32),
        PersonalizedSelectionGroup<String>(
          question: 'What is your current fitness goal?',
          groupValue: fitnessgoal,
          onChanged: (value) => setState(() => fitnessgoal = value ?? ''),
          options: const [
            SelectionOption(value: 'Lose Weight', title: 'Lose Weight', icon: Icons.monitor_weight_outlined),
            SelectionOption(value: 'Muscle Building', title: 'Build Muscle', icon: Icons.fitness_center_rounded),
            SelectionOption(value: 'Get in Shape', title: 'Maintain / Get in Shape', icon: Icons.favorite_border_rounded),
          ],
        ),
      ],
    )
  );

  Widget _buildPage2() => _buildPageContainer(
    'Choose a Companion',
    'Your companion will live on your dashboard and keep you motivated.',
    Column(
      children: [
        Center(child: SvgPicture.asset('assets/images/svg/signup_Screen.svg', height: 180)),
        const SizedBox(height: 32),
        PersonalizedSelectionGroup<String>(
          question: '',
          groupValue: petSelection,
          onChanged: (value) => setState(() => petSelection = value ?? ''),
          options: const [
            SelectionOption(value: 'Dog', title: 'A Loyal Dog', subtitle: 'Friendly, active, and always happy to see you.', icon: Icons.pets_rounded),
            SelectionOption(value: 'Cat', title: 'A Calm Cat', subtitle: 'Independent, serene, and observant.', icon: Icons.face_retouching_natural_rounded),
            SelectionOption(value: 'Random Illustration', title: 'Beautiful Abstract Art', subtitle: 'Soothing visuals that change organically.', icon: Icons.palette_outlined),
          ],
        ),
      ]
    )
  );

  Widget _buildPage3() => _buildPageContainer(
    'Establish a Routine',
    'Consistency is key. When would you like to reflect on your day?',
    PersonalizedSelectionGroup<String>(
      question: 'How often do you want reminders to journal?',
      groupValue: journalreminder,
      onChanged: (value) => setState(() => journalreminder = value ?? ''),
      options: const [
        SelectionOption(value: 'Morning', title: 'Morning (8:00 AM)', subtitle: 'Start the day with intention.', icon: Icons.wb_sunny_outlined),
        SelectionOption(value: 'Evening', title: 'Evening (6:00 PM)', subtitle: 'Reflect on the day as it winds down.', icon: Icons.wb_twilight_rounded),
        SelectionOption(value: 'Nightly', title: 'Nightly (9:00 PM)', subtitle: 'Clear your mind before sleep.', icon: Icons.nights_stay_outlined),
      ],
    )
  );

  // Helper widget to give metrics cards a beautiful unbounded height and padding
  Widget _buildMetricCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return _buildPageContainer(
      'Your Body Metrics',
      'This helps us calculate your calories and fitness milestones.',
      Column(
        children: [
          _buildMetricCard(
            title: 'Current Height',
            trailing: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildUnitToggle('cm', _isHeightCm, () => setState(() => _isHeightCm = true)),
                  _buildUnitToggle('ft/in', !_isHeightCm, () => setState(() => _isHeightCm = false)),
                ],
              ),
            ),
            child: _isHeightCm ? _buildCmHeightInput() : _buildFtHeightInput(),
          ),
          const SizedBox(height: 24),
          _buildMetricCard(
            title: 'Current Weight',
            child: _buildWeightInput('kg', weight, _weightController, (v) => setState(() => weight = v)),
          ),
          const SizedBox(height: 24),
          _buildMetricCard(
            title: 'Goal Weight',
            child: _buildWeightInput('kg', weightGoal, _weightGoalController, (v) => setState(() => weightGoal = v)),
          ),
        ],
      )
    );
  }

  Widget _buildUnitToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? MindurColors.sageMint : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withAlpha(120),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCmHeightInput() {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: VerticalWeightSlider(
            controller: _heightController,
            isVertical: false,
            unit: MeasurementUnit.inch, // Ensure package recognizes this or ignore
            decoration: PointerDecoration(
              width: 130,
              height: 3,
              largeColor: Colors.white.withAlpha(100),
              mediumColor: Colors.white.withAlpha(60),
              smallColor: Colors.white.withAlpha(30),
              gap: 30,
            ),
            indicator: Container(
              height: 4,
              width: 180,
              color: MindurColors.sageMint,
            ),
            onChanged: (val) {
              setState(() => height = val);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildTypableValue(
          value: height.toStringAsFixed(1),
          unit: 'cm',
          onChanged: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null && parsed > 50 && parsed < 250) {
              setState(() => height = parsed);
              // Wait for next frame to animate slider if possible
              Future.delayed(const Duration(milliseconds: 50), () {
                 // _heightController.animateTo(...) might not work for 3rd party, fallback to setState 
              });
            }
          }
        ),
      ],
    );
  }

  Widget _buildFtHeightInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFtInPicker(
          label: 'ft',
          value: _heightFt,
          min: 3,
          max: 8,
          onChanged: (v) => setState(() => _heightFt = v.toInt()),
        ),
        const SizedBox(width: 24),
        _buildFtInPicker(
          label: 'in',
          value: _heightIn,
          min: 0,
          max: 11,
          onChanged: (v) => setState(() => _heightIn = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildFtInPicker({required String label, required int value, required int min, required int max, required ValueChanged<double> onChanged}) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: value.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MindurColors.sageMint),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(10),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= min && parsed <= max) {
                    onChanged(parsed.toDouble());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(140),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightInput(String unitStr, double val, WeightSliderController controller, ValueChanged<double> onSliderChange) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: VerticalWeightSlider(
            controller: controller,
            isVertical: false,
            unit: MeasurementUnit.kg, // Keeps package happy
            decoration: PointerDecoration(
              width: 130,
              height: 3,
              largeColor: Colors.white.withAlpha(100),
              mediumColor: Colors.white.withAlpha(60),
              smallColor: Colors.white.withAlpha(30),
              gap: 30,
            ),
            indicator: Container(
              height: 4,
              width: 180,
              color: MindurColors.sageMint,
            ),
            onChanged: onSliderChange,
          ),
        ),
        const SizedBox(height: 16),
        _buildTypableValue(
          value: val.toStringAsFixed(1),
          unit: unitStr,
          onChanged: (input) {
            final parsed = double.tryParse(input);
            if (parsed != null && parsed > 10 && parsed < 300) {
              onSliderChange(parsed);
            }
          }
        ),
      ],
    );
  }

  Widget _buildTypableValue({required String value, required String unit, required Function(String) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: TextFormField(
            key: ValueKey(value), // Rebuilds nicely if slider moves
            initialValue: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: MindurColors.sageMint,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MindurColors.sageMint),
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(5),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          unit,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(140),
          ),
        ),
      ],
    );
  }
}
