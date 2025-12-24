class NutritionCalculator {
  /// Returns a map with maintenance, targetCalories & targetProtein
  static Map<String, double> calculate({
    required double age, // in years
    required double height, // in cm
    required double weight, // in kg
    required String goal,   // "Muscle Building", "Lose Weight", "Stay Fit"
    bool isMale = true, // default male
  }) {
    // ✅ BMR Calculation
    double bmr;

    if (isMale) {
      // Male BMR
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      // Female BMR (UNUSED for now)
      // bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      bmr = 0; // placeholder
    }

    // Maintenance calories = BMR * activity factor (assuming 1.3 sedentary)
    double maintenanceCalories = bmr * 1.3;

    double targetCalories = maintenanceCalories;
    double targetProtein = weight * 1.6;

    if (goal == "Muscle Building") {
      targetCalories = maintenanceCalories + 500; 
      targetProtein = weight * 2.0;
    } else if (goal == "Lose Weight") {
      targetCalories = maintenanceCalories - 300; 
      targetProtein = weight * 1.8;
    } else {
      // Stay Fit → maintain
      targetCalories = maintenanceCalories + 200;
      targetProtein = weight * 1.6;
    }

    return {
      "maintenance": maintenanceCalories,
      "calories": targetCalories,
      "protein": targetProtein,
    };
  }
}
