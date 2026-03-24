import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mindur/theme/app_background.dart';
import '../constant/datetime.dart';
import '../models/food_item.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

final firestoreService = FirestoreService();

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  final foodNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final foodquantityController = TextEditingController();

  bool _isSaving = false;

  void saveEntry() async {
    if (_isSaving) return;

    final foodName = foodNameController.text.trim();
    final calories = int.tryParse(caloriesController.text.trim()) ?? 0;
    final protein = int.tryParse(proteinController.text.trim()) ?? 0;
    final quantity = int.tryParse(foodquantityController.text.trim()) ?? 0;

    if (foodName.isEmpty || calories == 0 || protein == 0 || quantity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            "Please fill all fields correctly.",
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final foodItem = FoodItem(
        name: foodName,
        calories: calories * quantity,
        protein: protein * quantity,
        quantity: quantity,
      );

      await firestoreService.logFood(foodItem);

      // ✅ LOG FOOD LOGGED
      await AnalyticsService().logFoodLogged(
        foodName: foodItem.name,
        calories: foodItem.calories,
        protein: foodItem.protein,
      );

      if (!mounted) return;

      foodNameController.clear();
      caloriesController.clear();
      proteinController.clear();
      foodquantityController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Food entry saved successfully!"),
          duration: Duration(seconds: 2),
        ),
      );

      context.pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(TimeUtils.formattedDate),
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.chevronLeft),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  _buildTextField(context, foodNameController, 'Food Name'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context,
                    foodquantityController,
                    'Quantity (x)',
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context,
                    proteinController,
                    'Protein (per unit)',
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context,
                    caloriesController,
                    'Calories (per unit)',
                    isNumber: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: MediaQuery.of(context).size.width * 0.12,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : saveEntry,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextField(
      controller: controller,
      maxLines: 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.2),
        ),
      ),
    );
  }
}
