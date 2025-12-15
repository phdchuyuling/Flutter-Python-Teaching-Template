import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'models/user_model.dart';
import 'models/meal_model.dart';

void main() {
  runApp(CalorieApp());
}

// C1 漸層色（可由設定變更）
Color c1Start = Color(0xFF4FACFE);
Color c1End = Color(0xFF00F2FE);

// App-wide font scale (可由設定變更)
double appFontScale = 1.0;

class CalorieApp extends StatefulWidget {
  @override
  State<CalorieApp> createState() => _CalorieAppState();
}

class _CalorieAppState extends State<CalorieApp> {
  UserProfile? user;
  int _selectedIndex = 0;
  List<Meal> todayMeals = [];

  void _saveAppearance(double fontScale, Color start, Color end) {
    setState(() {
      appFontScale = fontScale;
      c1Start = start;
      c1End = end;
    });
  }

  void _addMeal(Meal meal) {
    setState(() {
      todayMeals.add(meal);
    });
  }

  void _removeMeal(Meal meal) {
    setState(() {
      todayMeals.removeWhere((m) =>
          m.timestamp == meal.timestamp &&
          m.name == meal.name &&
          m.calories == meal.calories);
    });
  }

  List<Widget> _pages() {
    if (user == null)
      return [
        SettingsPage(
            onSave: _saveUser,
            onAppearanceSave: _saveAppearance,
            currentUser: user)
      ];
    return [
      HomePage(
          user: user!,
          meals: todayMeals,
          onAdd: _addMeal,
          onRemove: _removeMeal),
      StatsPage(meals: todayMeals, onRemove: _removeMeal),
      SettingsPage(
          onSave: _saveUser,
          onAppearanceSave: _saveAppearance,
          currentUser: user),
    ];
  }

  void _saveUser(UserProfile u) {
    setState(() {
      user = u;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: c1Start,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: c1Start,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: Builder(builder: (context) {
        final pages = _pages();
        // clamp selected index to a valid range so we never index out of bounds
        final safeIndex = (_selectedIndex < 0)
            ? 0
            : (_selectedIndex >= pages.length
                ? pages.length - 1
                : _selectedIndex);

        return Scaffold(
          body: pages[safeIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              setState(() {
                // keep the raw selection so we can remember user's choice,
                // but build() clamps to a valid page when necessary
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: "今日"),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: "統計"),
              NavigationDestination(icon: Icon(Icons.settings), label: "設定"),
            ],
          ),
        );
      }),
    );
  }
}
