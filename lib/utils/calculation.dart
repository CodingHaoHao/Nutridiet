class CalculationUtils {
  static int calculateAge(DateTime birthday) {
    final today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }
  
  // Calculate BMR
  static int calculateBMR({
    required String gender,
    required double weight,
    required double height,
    required int age,
  }) {
    if (gender == 'Male') {
      return ((10 * weight) + (6.25 * height) - (5 * age) + 5).floor();
    } else {
      return ((10 * weight) + (6.25 * height) - (5 * age) - 161).floor();
    }
  }

  // Activity level 
  static double getActivityMultiplier(String activity) {
    switch (activity) {
      case 'Sedentary':
        return 1.2;
      case 'Lightly Active':
        return 1.375;
      case 'Moderately Active':
        return 1.55;
      case 'Very Active':
        return 1.725;
      default:
        return 1.2;
    }
  }

  // Calculate TDEE
  static int calculateTDEE(int bmr, String activityLevel) {
    final multiplier = getActivityMultiplier(activityLevel);
    return (bmr * multiplier).floor();
  }

  // Calculate recommended daily calories
  static int calculateRecommendedCalories({
    required int tdee,
    required double currentWeight,
    required double goalWeight,
    required int periodDays,
  }) {
    final weightDiff = goalWeight - currentWeight; 

    if (weightDiff == 0) return tdee; 

    // 1 kg = 7700 kcal
    const kcalPerKg = 7700;
    final totalKcal = (weightDiff.abs() * kcalPerKg).floor();
    final dailyKcalChange = (totalKcal / periodDays).floor();

    if (weightDiff < 0) {
      // user wants to lose weight
      return (tdee - dailyKcalChange).clamp(1200, tdee); // min safe intake 1200
    } else {
      // weightDiff > 0 = goal weight > current weight = user wants to gain weight
      return (tdee + dailyKcalChange);
    }
  }
}
