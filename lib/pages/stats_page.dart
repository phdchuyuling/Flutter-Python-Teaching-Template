import 'package:flutter/material.dart';
import '../widgets/gradient_scaffold.dart';
import '../models/meal_model.dart';
import '../widgets/simple_charts.dart';
import '../main.dart';

class StatsPage extends StatefulWidget {
  final List<Meal> meals;
  final void Function(Meal) onRemove;

  const StatsPage({super.key, required this.meals, required this.onRemove});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedRange = 1; // 0: day, 1: week, 2: month

  double totalForDay(DateTime day) {
    return widget.meals
        .where((m) => m.isSameDay(day))
        .fold(0.0, (s, m) => s + m.calories);
  }

  double totalForLastNDays(int n) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: n - 1));
    return widget.meals
        .where((m) => m.timestamp.isAfter(cutoff) || m.isSameDay(cutoff))
        .fold(0.0, (s, m) => s + m.calories);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayTotal = totalForDay(now);
    final weekTotal = totalForLastNDays(7);
    final prevWeekTotal = widget.meals
        .where((m) =>
            m.timestamp.isAfter(now.subtract(const Duration(days: 14))) &&
            m.timestamp.isBefore(now.subtract(const Duration(days: 7))))
        .fold(0.0, (s, m) => s + m.calories);
    final monthTotal = totalForLastNDays(30);
    final prevMonthTotal = widget.meals
        .where((m) =>
            m.timestamp.isAfter(now.subtract(const Duration(days: 60))) &&
            m.timestamp.isBefore(now.subtract(const Duration(days: 30))))
        .fold(0.0, (s, m) => s + m.calories);

    // prepare category totals and 7-day series
    final Map<String, double> categoryTotals = {};
    for (final m in widget.meals) {
      categoryTotals[m.category] =
          (categoryTotals[m.category] ?? 0) + m.calories;
    }

    // compute macronutrients sums (grams)
    double sumProtein = 0.0, sumFat = 0.0, sumCarbs = 0.0;
    for (final m in widget.meals) {
      sumProtein += m.protein;
      sumFat += m.fat;
      sumCarbs += m.carbs;
    }
    final proteinCals = sumProtein * 4.0;
    final fatCals = sumFat * 9.0;
    final carbsCals = sumCarbs * 4.0;
    final totalMacroCals = proteinCals + fatCals + carbsCals;

    final List<double> last7Values = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i)); // oldest -> newest
      return totalForDay(day);
    });
    final List<String> last7Labels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return '${day.month}/${day.day}';
    });

    return GradientScaffold(
      appBar: AppBar(title: const Text("統計")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleButtons(
                isSelected: List.generate(3, (i) => i == _selectedRange),
                onPressed: (i) => setState(() => _selectedRange = i),
                children: const [Text('今日'), Text('一週'), Text('一個月')],
              ),
              const SizedBox(height: 20),
              // charts: category breakdown and 7-day trend
              // macronutrient donut summary (always shown, uses grams if available)
              Text('每日營養目標與三大營養素',
                  style: TextStyle(
                      fontSize: 16 * appFontScale, color: Colors.white)),
              const SizedBox(height: 8),
              DonutChart(
                proteinCalories: proteinCals,
                fatCalories: fatCals,
                carbsCalories: carbsCals,
                totalCalories: totalMacroCals,
                proteinGrams: sumProtein,
                fatGrams: sumFat,
                carbsGrams: sumCarbs,
              ),
              const SizedBox(height: 12),
              if (categoryTotals.isNotEmpty) ...[
                Text('分類攝取分布',
                    style: TextStyle(
                        fontSize: 16 * appFontScale, color: Colors.white)),
                const SizedBox(height: 8),
                SizedBox(
                    height: 160, child: CategoryBarChart(data: categoryTotals)),
                const SizedBox(height: 12),
              ],
              Text('近 7 日趨勢',
                  style: TextStyle(
                      fontSize: 16 * appFontScale, color: Colors.white)),
              const SizedBox(height: 8),
              SizedBox(
                  height: 160,
                  child: SimpleLineChart(
                      values: last7Values, labels: last7Labels)),
              const SizedBox(height: 12),
              if (_selectedRange == 0) ...[
                Text('今日總攝取：${dayTotal.toStringAsFixed(0)} 大卡',
                    style: TextStyle(
                        fontSize: 22 * appFontScale, color: Colors.white)),
              ] else if (_selectedRange == 1) ...[
                Text('本週總攝取：${weekTotal.toStringAsFixed(0)} 大卡',
                    style: TextStyle(
                        fontSize: 22 * appFontScale, color: Colors.white)),
                const SizedBox(height: 8),
                Text('上週總攝取：${prevWeekTotal.toStringAsFixed(0)} 大卡',
                    style: TextStyle(
                        fontSize: 16 * appFontScale, color: Colors.white70)),
              ] else ...[
                Text('本月 (30天) 總攝取：${monthTotal.toStringAsFixed(0)} 大卡',
                    style: TextStyle(
                        fontSize: 22 * appFontScale, color: Colors.white)),
                const SizedBox(height: 8),
                Text('上個 30 天：${prevMonthTotal.toStringAsFixed(0)} 大卡',
                    style: TextStyle(
                        fontSize: 16 * appFontScale, color: Colors.white70)),
              ],
              const SizedBox(height: 20),
              Text('詳細紀錄：',
                  style: TextStyle(
                      fontSize: 18 * appFontScale, color: Colors.white)),
              const SizedBox(height: 8),
              // list of records — rendered inside the scroll view
              widget.meals.isEmpty
                  ? const Center(
                      child:
                          Text('尚無紀錄', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.meals.length,
                      itemBuilder: (context, index) {
                        final m = widget.meals[widget.meals.length - 1 - index];
                        return ListTile(
                          title: Text(m.name,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * appFontScale)),
                          subtitle: Text('${m.timestamp.toLocal()}',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12 * appFontScale)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${m.calories.toStringAsFixed(0)} 大卡',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * appFontScale)),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => widget.onRemove(m),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
