class Meal {
  final String id;
  final String name;
  final double calories;
  final String category; // e.g. 早餐、午餐、晚餐、點心、其他
  final String foodType; // e.g. 蛋白質、全穀雜糧、蔬菜、水果、飲品
  final double protein; // grams
  final double fat; // grams
  final double carbs; // grams
  final DateTime timestamp;

  Meal(
      {required this.id,
      required this.name,
      required this.calories,
      this.category = '其他',
      this.foodType = '其他',
      this.protein = 0.0,
      this.fat = 0.0,
      this.carbs = 0.0,
      DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  /// Convenience: check same calendar day
  bool isSameDay(DateTime other) {
    return timestamp.year == other.year &&
        timestamp.month == other.month &&
        timestamp.day == other.day;
  }
}
