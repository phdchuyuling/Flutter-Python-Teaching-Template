import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的預算App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '我的預算'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BudgetRecord> records = [];
  DateTime currentMonth = DateTime.now();

  void _addRecord(BudgetRecord record) {
    setState(() {
      records.add(record);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        elevation: 0,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddRecordPage(onRecordAdded: _addRecord),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text(
                '新增紀錄',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthlySummaryPage(
                      records: records,
                      currentMonth: currentMonth,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text(
                '當月總計',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            _buildCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  currentMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month - 1,
                  );
                });
              },
            ),
            Text(
              '${currentMonth.year}年${currentMonth.month}月',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () {
                setState(() {
                  currentMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              int day =
                  index -
                  DateTime(currentMonth.year, currentMonth.month, 1).weekday +
                  2;
              bool isCurrentMonth =
                  day > 0 && day <= _getDaysInMonth(currentMonth);

              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: day == DateTime.now().day && isCurrentMonth
                        ? Colors.blue
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    isCurrentMonth ? day.toString() : '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}

class AddRecordPage extends StatefulWidget {
  final Function(BudgetRecord) onRecordAdded;
  const AddRecordPage({super.key, required this.onRecordAdded});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();

  String amountInput = '';
  String customCategoryText = '';

  final List<String> categories = [
    '餐飲',
    '交通',
    '旅遊',
    '購物',
    '水電',
    '住房／租房',
    '網路／電信',
    '其他（自訂輸入）',
  ];

  final TextEditingController _customController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text('新增紀錄'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${currentMonth.year}年${currentMonth.month}月',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                int day =
                    index -
                    DateTime(currentMonth.year, currentMonth.month, 1).weekday +
                    2;
                bool isCurrentMonth =
                    day > 0 && day <= _getDaysInMonth(currentMonth);
                bool isSelected =
                    isCurrentMonth &&
                    day == selectedDate.day &&
                    selectedDate.month == currentMonth.month &&
                    selectedDate.year == currentMonth.year;

                return GestureDetector(
                  onTap: isCurrentMonth
                      ? () {
                          setState(() {
                            selectedDate = DateTime(
                              currentMonth.year,
                              currentMonth.month,
                              day,
                            );
                          });
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isCurrentMonth ? day.toString() : '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 使用 isExpanded 確保 dropdown 顯示完整
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[700],
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(filled: false),
                  hint: const Text(
                    '選擇分類',
                    style: TextStyle(color: Colors.white),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      if (value != '其他（自訂輸入）') {
                        customCategoryText = '';
                        _customController.text = '';
                      }
                    });
                  },
                ),
                if (selectedCategory == '其他（自訂輸入）')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: _customController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '請輸入自訂分類',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {
                          customCategoryText = v.trim();
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '金額 (輸入 + 表示收入: 例如 +1000)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: (value) {
                    setState(() {
                      amountInput = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _canAddRecord()
                      ? () {
                          // 支援全形＋轉為半形 +
                          String s = amountInput.replaceAll('＋', '+').trim();
                          bool isIncome = false;
                          if (s.startsWith('+')) {
                            isIncome = true;
                            s = s.substring(1);
                          }
                          // 移除千分位或非數字（保留小數點、負號）
                          s = s.replaceAll(RegExp(r'[,¥$￥\s]'), '');
                          final parsed = double.tryParse(s) ?? 0;
                          if (parsed <= 0) return;

                          final categoryToUse = selectedCategory == '其他（自訂輸入）'
                              ? (customCategoryText.isNotEmpty
                                    ? customCategoryText
                                    : '其他')
                              : selectedCategory!;

                          final record = BudgetRecord(
                            category: categoryToUse,
                            amount: parsed,
                            date: selectedDate,
                            isIncome: isIncome,
                          );

                          widget.onRecordAdded(record);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('新增'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddRecord() {
    if (selectedCategory == null) return false;
    if (selectedCategory == '其他（自訂輸入）' && customCategoryText.trim().isEmpty)
      return false;
    String s = amountInput.replaceAll('＋', '+').trim();
    if (s.isEmpty) return false;
    if (s.startsWith('+')) s = s.substring(1);
    s = s.replaceAll(RegExp(r'[,¥$￥\s]'), '');
    final parsed = double.tryParse(s) ?? 0;
    return parsed > 0;
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}

class MonthlySummaryPage extends StatelessWidget {
  final List<BudgetRecord> records;
  final DateTime currentMonth;

  const MonthlySummaryPage({
    super.key,
    required this.records,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    // 取出當月紀錄
    final monthRecords = records.where((r) {
      return r.date.year == currentMonth.year &&
          r.date.month == currentMonth.month;
    }).toList();

    double incomeTotal = 0;
    double expenseTotal = 0;
    for (var r in monthRecords) {
      if (r.isIncome) {
        incomeTotal += r.amount;
      } else {
        expenseTotal += r.amount;
      }
    }
    final netTotal = incomeTotal - expenseTotal;

    String fmt(double v) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toStringAsFixed(2);
    }

    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text('當月統計'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {},
                ),
                Text(
                  '${currentMonth.year}年${currentMonth.month}月',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('當月紀錄', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  // 若沒有紀錄顯示提示
                  if (monthRecords.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('本月尚無紀錄'),
                    ),
                  // 列出每筆紀錄：日期、分類、金額（收入顯示 +，支出顯示 -）
                  ...monthRecords.map((r) {
                    final sign = r.isIncome ? '+' : '-';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 顯示日與分類
                          Expanded(
                            child: Text(
                              '${r.date.day}日  ${r.category}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$sign${fmt(r.amount)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: r.isIncome
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  // 小計：收入 / 支出 / 淨額
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '當月收入總計：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+${fmt(incomeTotal)} 元',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '當月支出總計：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${fmt(expenseTotal)} 元',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '淨額 (收入 - 支出)：',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          (netTotal >= 0
                                  ? '+${fmt(netTotal)}'
                                  : fmt(netTotal)) +
                              ' 元',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: netTotal >= 0
                                ? Colors.green[800]
                                : Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetRecord {
  String category;
  double amount;
  DateTime date;
  bool isIncome;

  BudgetRecord({
    required this.category,
    required this.amount,
    required this.date,
    this.isIncome = false,
  });
}
