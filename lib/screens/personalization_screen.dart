
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mindur/theme/app_background.dart';
import 'package:vertical_weight_slider/vertical_weight_slider.dart';

import '../components/homescreen_cards.dart';
import '../components/personalized_radio_input.dart';
import '../services/firebase_service.dart';
import 'main_screen.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  String petSelection = '';
  String fitnessgoal = '';
  String appgoal = '';
  String journalreminder = '';

  late final WeightSliderController _weightController;
  late final WeightSliderController _weightGoalController;
  late final WeightSliderController _heightController;

  double weight = 40.0;
  double weightGoal = 70.0;
  double height = 120.0;

  @override
  void initState() {
    super.initState();

    _weightController = WeightSliderController(
      initialWeight: weight,
      minWeight: 40,
      interval: 0.2,
    );

    _weightGoalController = WeightSliderController(
      initialWeight: weightGoal,
      minWeight: 40,
      interval: 0.3,
    );

    _heightController = WeightSliderController(
      initialWeight: height,
      minWeight: 120,
      maxWeight: 200,
      interval: 0.5,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightGoalController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBackground(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/images/svg/signup_Screen.svg',
                  height: 250,
                  width: 250,
                ),
                const SizedBox(height: 16),
      
                Text(
                  'Let\'s personalize your experience',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
      
                const SizedBox(height: 16),
      
                PerosnalizedRadioInput(
                  question: 'What would you prefer to see on your dashboard?',
                  selectedValue: 'Dog',
                  selectedValueb: 'Cat',
                  selectedValuec: 'Random Illustration',
                  groupValue: petSelection,
                  onChanged: (value) =>
                      setState(() => petSelection = value.toString()),
                ),
      
                const SizedBox(height: 16),
      
                PerosnalizedRadioInput(
                  question: 'What\'s your fitness goal?',
                  selectedValue: 'Muscle Building',
                  selectedValueb: 'Lose Weight',
                  selectedValuec: 'Get in Shape',
                  groupValue: fitnessgoal,
                  onChanged: (value) =>
                      setState(() => fitnessgoal = value.toString()),
                ),
      
                const SizedBox(height: 16),
      
                PerosnalizedRadioInput(
                  question: 'What’s your main goal with this app?',
                  selectedValue: 'Journaling & self-reflection',
                  selectedValueb: 'Building habits & discipline',
                  selectedValuec: 'Fitness & food tracking',
                  groupValue: appgoal,
                  onChanged: (value) =>
                      setState(() => appgoal = value.toString()),
                ),
      
                const SizedBox(height: 16),
      
                PerosnalizedRadioInput(
                  question:
                      'How often do you want reminders to reflect or journal?',
                  selectedValue: 'Morning',
                  selectedValueb: 'Evening',
                  selectedValuec: 'Nightly',
                  groupValue: journalreminder,
                  onChanged: (value) =>
                      setState(() => journalreminder = value.toString()),
                ),
      
                const SizedBox(height: 24),
      
                /// HEIGHT
                HomescreenCards(
                  height: 352,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tell us your height',
                        style: theme.textTheme.titleMedium,
                      ),
                      VerticalWeightSlider(
                        controller: _heightController,
                        isVertical: false,
                        unit: MeasurementUnit.kg,
                        decoration: PointerDecoration(
                          width: 130,
                          height: 3,
                          largeColor: colors.outline,
                          mediumColor: colors.outlineVariant,
                          smallColor: colors.surfaceContainerHighest,
                          gap: 30,
                        ),
                        indicator: Container(
                          height: 3,
                          width: 200,
                          color: colors.primary,
                        ),
                        onChanged: (value) =>
                            setState(() => height = value),
                      ),
                      Text(
                        '${height.toStringAsFixed(1)} cm',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
      
                const SizedBox(height: 16),
      
                /// CURRENT WEIGHT
                HomescreenCards(
                  height: 352,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tell us your current weight',
                        style: theme.textTheme.titleMedium,
                      ),
                      VerticalWeightSlider(
                        controller: _weightController,
                        isVertical: false,
                        unit: MeasurementUnit.kg,
                        decoration: PointerDecoration(
                          width: 130,
                          height: 3,
                          largeColor: colors.outline,
                          mediumColor: colors.outlineVariant,
                          smallColor: colors.surfaceContainerHighest,
                          gap: 30,
                        ),
                        indicator: Container(
                          height: 3,
                          width: 200,
                          color: colors.secondary,
                        ),
                        onChanged: (value) =>
                            setState(() => weight = value),
                      ),
                      Text(
                        '${weight.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
      
                const SizedBox(height: 16),
      
                /// GOAL WEIGHT
                HomescreenCards(
                  height: 352,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tell us your goal weight',
                        style: theme.textTheme.titleMedium,
                      ),
                      VerticalWeightSlider(
                        controller: _weightGoalController,
                        isVertical: false,
                        unit: MeasurementUnit.kg,
                        decoration: PointerDecoration(
                          width: 130,
                          height: 3,
                          largeColor: colors.outline,
                          mediumColor: colors.outlineVariant,
                          smallColor: colors.surfaceContainerHighest,
                          gap: 30,
                        ),
                        indicator: Container(
                          height: 3,
                          width: 200,
                          color: colors.primary,
                        ),
                        onChanged: (value) =>
                            setState(() => weightGoal = value),
                      ),
                      Text(
                        '${weightGoal.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
      
                const SizedBox(height: 24),
      
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  height: MediaQuery.sizeOf(context).width * 0.08,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (petSelection.isEmpty ||
                          fitnessgoal.isEmpty ||
                          appgoal.isEmpty ||
                          journalreminder.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please answer all questions!'),
                          ),
                        );
                        return;
                      }
      
                      await FirestoreService().saveUserPersonalization(
                        petSelection: petSelection,
                        fitnessGoal: fitnessgoal,
                        appGoal: appgoal,
                        journalReminder: journalreminder,
                        height: height,
                        currentWeight: weight,
                        goalWeight: weightGoal,
                      );
      
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainScreen(),
                        ),
                      );
                    },
                    child: const Text('Next'),
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
