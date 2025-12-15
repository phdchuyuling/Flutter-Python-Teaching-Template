import 'package:flutter/material.dart';
import '../widgets/gradient_scaffold.dart';
import '../models/meal_model.dart';

class AddMealPage extends StatefulWidget {
  final void Function(Meal) onAdd;

  const AddMealPage({super.key, required this.onAdd});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final List<String> _categories = ['早餐', '午餐', '晚餐', '點心', '其他'];
  String _selectedCategory = '其他';
  // 新增的食物類型（第三排）
  final List<String> _foodTypes = ['蛋白質', '全穀雜糧', '蔬菜', '水果', '飲品'];
  String _selectedFoodType = '蛋白質';
  DateTime _selectedDateTime = DateTime.now();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day,
          _selectedDateTime.hour, _selectedDateTime.minute);
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (t == null) return;
    setState(() {
      _selectedDateTime = DateTime(_selectedDateTime.year,
          _selectedDateTime.month, _selectedDateTime.day, t.hour, t.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text("新增餐點")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 餐別放最前面
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? '其他'),
              decoration: const InputDecoration(labelText: '餐別'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "餐點名稱"),
            ),
            const SizedBox(height: 12),
            // 日期與時間選擇
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(
                        '${_selectedDateTime.year}-${_selectedDateTime.month.toString().padLeft(2, '0')}-${_selectedDateTime.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(
                        '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 第三排：食物類型（蛋白質 / 全穀雜糧 / 蔬菜 / 水果 / 飲品）
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('食物類型',
                      style: Theme.of(context).textTheme.bodyLarge),
                )),
            Wrap(
              spacing: 8,
              children: _foodTypes.map((t) {
                final selected = t == _selectedFoodType;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) _selectedFoodType = t;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesCtrl,
              decoration: const InputDecoration(labelText: "熱量(大卡)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            // 可選：輸入三大營養素（克）以便統計
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinCtrl,
                    decoration: const InputDecoration(labelText: "蛋白質 (g)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatCtrl,
                    decoration: const InputDecoration(labelText: "脂肪 (g)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsCtrl,
                    decoration: const InputDecoration(labelText: "碳水 (g)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final meal = Meal(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: _nameCtrl.text,
                  calories: double.tryParse(_caloriesCtrl.text) ?? 0,
                  category: _selectedCategory,
                  foodType: _selectedFoodType,
                  protein: double.tryParse(_proteinCtrl.text) ?? 0.0,
                  fat: double.tryParse(_fatCtrl.text) ?? 0.0,
                  carbs: double.tryParse(_carbsCtrl.text) ?? 0.0,
                  timestamp: _selectedDateTime,
                );
                widget.onAdd(meal);
                // If this page was pushed (can pop), return to previous screen.
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${meal.name} 已加入！")));
                  _nameCtrl.clear();
                  _caloriesCtrl.clear();
                  _proteinCtrl.clear();
                  _fatCtrl.clear();
                  _carbsCtrl.clear();
                }
              },
              child: const Text("新增"),
            ),
          ],
        ),
      ),
    );
  }
}
