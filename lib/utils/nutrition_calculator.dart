class NutritionCalculator {
  /// Calculates daily nutrition targets
  ///
  /// Returns:
  /// - maintenance: calories to maintain weight
  /// - calories: target calories based on goal
  /// - protein: grams/day
  static Map<String, double> calculate({
    required double age, // years
    required double height, // cm
    required double weight, // kg
    required String goal, // "Muscle Building", "Lose Weight", "Stay Fit"
    bool isMale = true, // false = female
  }) {
    // Activity level: average student + working professional
    const double activityLevel = 1.5;

    // BMR (Mifflin–St Jeor)
    final double bmr = isMale
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    // Maintenance calories
    final double maintenanceCalories = bmr * activityLevel;

    double targetCalories;
    double targetProtein;

    switch (goal) {
      case "Muscle Building":
        // Lean bulk (~12% surplus)
        targetCalories = maintenanceCalories * 1.12;
        targetProtein = weight * 2.0;
        break;

      case "Lose Weight":
        // Sustainable cut (~15% deficit)
        targetCalories = maintenanceCalories * 0.85;
        targetProtein = weight * 1.9;
        break;

      default: // Stay Fit
        targetCalories = maintenanceCalories;
        targetProtein = weight * 1.6;
    }

    return {
      "maintenance": maintenanceCalories.roundToDouble(),
      "calories": targetCalories.roundToDouble(),
      "protein": targetProtein.roundToDouble(),
    };
  }
}
