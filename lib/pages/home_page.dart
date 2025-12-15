import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../widgets/gradient_scaffold.dart';
import 'add_meal_page.dart';

class HomePage extends StatefulWidget {
  final UserProfile user;
  final List<Meal> meals;
  final void Function(Meal) onAdd;
  final void Function(Meal) onRemove;

  const HomePage(
      {Key? key,
      required this.user,
      required this.meals,
      required this.onAdd,
      required this.onRemove})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  static const int _middlePage = 1200;
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _middlePage);
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _addMonths(DateTime from, int months) {
    final y = from.year + ((from.month - 1 + months) ~/ 12);
    final m = ((from.month - 1 + months) % 12) + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final d = from.day.clamp(1, lastDay);
    return DateTime(y, m, d);
  }

  List<Meal> _mealsForDay(DateTime day) {
    return widget.meals.where((m) {
      final t = m.timestamp;
      return t.year == day.year && t.month == day.month && t.day == day.day;
    }).toList();
  }

  Widget _buildMonthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final weekDayOfFirst = (first.weekday + 6) % 7; // make Monday=0
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = weekDayOfFirst + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final cells = <Widget>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < 7; c++) {
        final idx = r * 7 + c;
        final dayNum = idx - weekDayOfFirst + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          cells.add(const SizedBox.shrink());
        } else {
          final dt = DateTime(month.year, month.month, dayNum);
          final hasMeals = _mealsForDay(dt).isNotEmpty;
          final selected = dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month &&
              dt.day == _selectedDate.day;
          cells.add(GestureDetector(
            onTap: () => setState(() => _selectedDate = dt),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                      alignment: Alignment.topCenter,
                      child: Text('$dayNum',
                          style: const TextStyle(color: Colors.white))),
                  if (hasMeals)
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle))),
                ],
              ),
            ),
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text('${month.year} / ${month.month}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                  onPressed: _jumpToToday,
                  child: const Text('回本月',
                      style: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['一', '二', '三', '四', '五', '六', '日']
                  .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: const TextStyle(color: Colors.white70)))))
                  .toList()),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: cells,
        ),
      ],
    );
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
    _pageController.animateToPage(_middlePage,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('飲食紀錄')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;

          Widget leftColumn() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      final offset = idx - _middlePage;
                      setState(() {
                        _visibleMonth = _addMonths(
                            DateTime(
                                DateTime.now().year, DateTime.now().month, 1),
                            offset);
                        // if selected date is outside month, clamp to first day
                        if (!(_selectedDate.year == _visibleMonth.year &&
                            _selectedDate.month == _visibleMonth.month)) {
                          _selectedDate = DateTime(
                              _visibleMonth.year, _visibleMonth.month, 1);
                        }
                      });
                    },
                    itemBuilder: (ctx, idx) {
                      final offset = idx - _middlePage;
                      final month = _addMonths(
                          DateTime(
                              DateTime.now().year, DateTime.now().month, 1),
                          offset);
                      return _buildMonthGrid(month);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryForSelectedDay(),
              ],
            );
          }

          Widget rightArea() {
            final sorted = List<Meal>.from(widget.meals)
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('詳細紀錄', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white24),
                    itemBuilder: (context, i) {
                      final m = sorted[i];
                      return ListTile(
                        title: Text(m.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            '${m.timestamp.year}-${m.timestamp.month.toString().padLeft(2, '0')}-${m.timestamp.day.toString().padLeft(2, '0')} ${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white70)),
                        trailing: Text('${m.calories.toStringAsFixed(0)} 大卡',
                            style: const TextStyle(color: Colors.white)),
                        onLongPress: () => widget.onRemove(m),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          if (wide) {
            return Row(
              children: [
                SizedBox(width: 360, child: leftColumn()),
                const SizedBox(width: 12),
                Expanded(child: rightArea()),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                leftColumn(),
                const SizedBox(height: 12),
                SizedBox(height: 300, child: rightArea()),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddMealPage(onAdd: widget.onAdd))),
        label: const Text('新增餐點'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryForSelectedDay() {
    final meals = _mealsForDay(_selectedDate);
    final total = meals.fold<double>(0, (s, m) => s + m.calories);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${_selectedDate.month}月${_selectedDate.day}日' +
                  (_selectedDate.year == DateTime.now().year &&
                          _selectedDate.month == DateTime.now().month &&
                          _selectedDate.day == DateTime.now().day
                      ? ' (今天)'
                      : ''),
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withOpacity(0.9),
            child: Column(
              children: [
                if (meals.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child:
                          Text('今日尚無餐點', style: TextStyle(fontSize: 14 * 1.0))),
                ...meals.map((m) => Column(children: [
                      ListTile(
                        title: Text(m.name),
                        trailing: Text('${m.calories.toStringAsFixed(0)} 大卡'),
                        subtitle: Text(m.category),
                        onLongPress: () => widget.onRemove(m),
                      ),
                      const Divider(height: 1),
                    ])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BMI： ${widget.user.bmi.toStringAsFixed(1)}'),
                    const SizedBox(height: 6),
                    Text(
                        '每日所需熱量： ${widget.user.dailyCalories.toStringAsFixed(0)} 大卡',
                        style: const TextStyle(color: Colors.blue)),
                    const SizedBox(height: 8),
                    Text('今日總攝取： ${total.toStringAsFixed(0)} 大卡'),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
