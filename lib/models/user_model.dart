class UserProfile {
  final double height; // cm
  final double weight; // kg
  final int age;
  final String workLevel; // 輕度/中度/重度

  UserProfile({
    required this.height,
    required this.weight,
    required this.age,
    required this.workLevel,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  double get dailyCalories {
    double calories = 0;
    if (bmi < 18.5) {
      if (workLevel == "輕度") calories = weight * 35;
      if (workLevel == "中度") calories = weight * 40;
      if (workLevel == "重度") calories = weight * 45;
    } else if (bmi < 24) {
      if (workLevel == "輕度") calories = weight * 30;
      if (workLevel == "中度") calories = weight * 35;
      if (workLevel == "重度") calories = weight * 40;
    } else {
      if (workLevel == "輕度") calories = weight * 22.5;
      if (workLevel == "中度") calories = weight * 30;
      if (workLevel == "重度") calories = weight * 35;
    }
    return calories;
  }
}
