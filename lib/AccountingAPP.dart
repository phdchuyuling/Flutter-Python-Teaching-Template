import 'package:flutter/material.dart';
// 匯入 intl 套件，用於日期格式化和本地化
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- 狀態定義 ---
enum ViewState { main, addRecord, monthlySummary }

Future<void> main() async {
  // 必須在執行 runApp 之前確保 Flutter Binding 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日期格式化數據，用於支援中文 (zh_TW)
  await initializeDateFormatting('zh_TW', null);
  Intl.defaultLocale = 'zh_TW';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 移除右上角的 Debug 標籤
      title: '可攜式記帳 App',
      // 使用深色背景來匹配您的設計
      theme: ThemeData(
        // 配置 App 主題色
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF333333),
          secondary: const Color(0xFFF7D5D3), // 米粉色
          background: const Color(0xFF333333),
          surface: const Color(0xFF444444), // 用於日曆背景
        ),
        scaffoldBackgroundColor: const Color(0xFF333333),
        useMaterial3: true,
      ),
      home: const BudgetApp(),
    );
  }
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key});

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  // 應用程式當前狀態
  ViewState _currentView = ViewState.main;

  // 預設選中的日期 (預設為今天)
  DateTime _selectedDate = DateTime.now();

  // --- 狀態變數 ---
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  String? _selectedCategory;

  // 記帳類別數據
  final List<String> categories = [
    "餐飲",
    "交通",
    "旅遊",
    "水電",
    "住宿 / 房租",
    "網路 / 電信",
    "其他 【自訂輸入】",
  ];

  // 模擬當月總結數據 - 儲存用戶新增的紀錄
  final List<Map<String, dynamic>> _records = [];

  // 【修復 1】: 加上 dispose 方法，釋放記憶體
  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  // 計算當月總計 (淨額)
  double get monthlyTotal {
    final currentMonth = _selectedDate.month;
    final currentYear = _selectedDate.year;
    // 總和所有有符號的金額 (使用 double 以支援小數)
    return _records
        .where(
          (r) =>
              r['date'].year == currentYear && r['date'].month == currentMonth,
        )
        .fold(0.0, (sum, record) => sum + (record['amount'] as double));
  }

  // 儲存紀錄的邏輯
  void _saveRecord(BuildContext context) {
    // 收起鍵盤
    FocusScope.of(context).unfocus();

    String finalCategory = _selectedCategory ?? "";

    // 處理自訂類別輸入
    if (finalCategory == "其他 【自訂輸入】") {
      final customInput = _customCategoryController.text.trim();
      if (customInput.isEmpty) {
        _showSnackBar(context, '請輸入自訂項目名稱');
        return;
      }
      finalCategory = customInput; // 使用自訂輸入作為最終類別
    }

    if (finalCategory.isEmpty || _amountController.text.isEmpty) {
      _showSnackBar(context, '請選擇類別並輸入金額');
      return;
    }

    // 處理金額和符號 (+ for income)
    final rawAmountText = _amountController.text.trim();
    bool isIncome = rawAmountText.startsWith('+');
    // 如果有 + 號，去掉它；如果有 - 號，也先去掉，統一轉成數字
    String numericalText =
        rawAmountText.replaceAll('+', '').replaceAll('-', '');

    // 【修復 2】: 改用 double.tryParse 支援小數點
    final amountValue = double.tryParse(numericalText);

    if (amountValue == null || amountValue <= 0) {
      _showSnackBar(context, '請輸入有效的金額 (例如: 100 或 +1000)');
      return;
    }

    // 儲存有符號的金額：收入為正，支出為負
    final signedAmount = isIncome ? amountValue : -amountValue;
    final displaySign = isIncome ? '收入' : '支出';

    // 儲存紀錄
    setState(() {
      _records.add({
        "date": DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
        "category": finalCategory,
        "amount": signedAmount,
      });

      // 清空表單並切換回主頁面
      _amountController.clear();
      _customCategoryController.clear();
      _selectedCategory = null;
      _currentView = ViewState.main;

      _showSnackBar(
        context,
        '成功儲存 $displaySign ($finalCategory)：${amountValue.toStringAsFixed(0)} 元！',
      );
    });
  }

  // 顯示提示訊息的 Helper
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating, // 懸浮樣式比較好看
      ),
    );
  }

  // --- 介面建構 helpers (日曆部分) ---

  // 頂部日曆介面
  Widget _buildCalendar(DateTime focusedDay) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekDay = firstDayOfMonth.weekday % 7; // 0=Sun, 1=Mon...

    List<Widget> dayWidgets = [];

    // 星期標題
    const dayNames = ['日', '一', '二', '三', '四', '五', '六'];

    // 填補上個月的天數
    for (int i = 0; i < firstDayWeekDay; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // 當月天數
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedDay.year, focusedDay.month, day);
      final isSelected = date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: isSelected
                ? const BoxDecoration(
                    color: Color(0xFF90A4AE), // 選中日的背景色
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              '$day',
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          // 月份切換標題
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedDate =
                        DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('yyyy年MM月').format(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedDate =
                        DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                  });
                },
              ),
            ],
          ),

          // 星期標題
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dayNames
                  .map((d) => Text(d, style: const TextStyle(color: Colors.white70)))
                  .toList(),
            ),
          ),

          // 日期網格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
            ),
            itemCount: dayWidgets.length,
            itemBuilder: (context, index) {
              return dayWidgets[index];
            },
          ),
        ],
      ),
    );
  }

  // 頂部導航區
  Widget _buildTopNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 返回鍵
        Container(
          decoration: BoxDecoration(
            color: _currentView != ViewState.main
                ? Colors.white12
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: _currentView != ViewState.main
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _currentView = ViewState.main;
                    });
                  },
                )
              : const SizedBox(width: 40, height: 40),
        ),
        // Home 鍵
        Container(
          decoration: const BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.home, color: Colors.white, size: 20),
            onPressed: () {
              setState(() {
                FocusScope.of(context).unfocus();
                _currentView = ViewState.main;
              });
            },
          ),
        ),
      ],
    );
  }

  // 按鈕樣式
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2, // 加一點陰影比較有立體感
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 1. 主頁面底部內容
  Widget _buildMainView() {
    return Column(
      children: [
        _buildActionButton(
          text: '新增紀錄',
          onPressed: () {
            setState(() {
              _currentView = ViewState.addRecord;
            });
          },
        ),
        _buildActionButton(
          text: '當月總計',
          onPressed: () {
            setState(() {
              _currentView = ViewState.monthlySummary;
            });
          },
        ),
      ],
    );
  }

  // 2. 新增紀錄底部內容
  Widget _buildAddRecordView() {
    final isCustomCategorySelected = _selectedCategory == "其他 【自訂輸入】";

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部標題
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '新增紀錄',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.edit_note, color: Colors.black),
            ],
          ),
          const SizedBox(height: 15),

          // 類別列表
          Wrap(
            // 使用 Wrap 讓選項自動換行，避免超出螢幕
            spacing: 8.0,
            runSpacing: 8.0,
            children: categories.map((category) {
              final isSelected = category == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // 自訂類別輸入欄位
          if (isCustomCategorySelected)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: TextField(
                controller: _customCategoryController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: '輸入自訂項目',
                  filled: true,
                  fillColor: Colors.white70,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // 金額輸入欄位
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ), // 支援數字鍵盤
            decoration: InputDecoration(
              labelText: '金額',
              hintText: '輸入 100 (支出) 或 +1000 (收入)',
              labelStyle: const TextStyle(color: Colors.black87),
              hintStyle: const TextStyle(color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white70,
              prefixIcon: const Icon(Icons.attach_money, color: Colors.black),
              isDense: true,
            ),
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),

          const SizedBox(height: 20),

          // 儲存按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveRecord(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '儲存紀錄',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. 當月總計底部內容
  Widget _buildMonthlySummaryView() {
    final currentMonth = _selectedDate.month;
    final filteredRecords = _records
        .where(
          (r) =>
              r['date'].year == _selectedDate.year &&
              r['date'].month == currentMonth,
        )
        .toList();

    final netBalance = monthlyTotal;
    final netDisplay = netBalance.abs().toStringAsFixed(0); // 去掉小數點顯示
    final statusText = netBalance >= 0 ? '淨賺' : '淨虧';
    final statusColor = netBalance >= 0
        ? const Color.fromARGB(255, 14, 126, 68)
        : Colors.red[700];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '當月總計',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.bar_chart, color: Colors.black),
            ],
          ),
          const SizedBox(height: 15),
          if (filteredRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  '本月尚無紀錄',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            )
          else ...[
            // 限制高度，如果紀錄太多可以滑動，不會讓介面爆掉
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: filteredRecords.map((r) {
                    final isIncome = (r['amount'] as double) >= 0;
                    final sign = isIncome ? '+' : '-';
                    final amountAbs = (r['amount'] as double).abs().toStringAsFixed(0);
                    final date = r['date'] as DateTime;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r['category'],
                        style: const TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        DateFormat('MM/dd').format(date),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: Text(
                        '$sign$amountAbs',
                        style: TextStyle(
                          color: isIncome ? const Color(0xFF0E7E44) : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(color: Colors.black54, thickness: 1.0, height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${netBalance >= 0 ? '+' : '-'}$netDisplay',
                  style: TextStyle(
                      color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopNavigation(),
        const SizedBox(height: 12),
        _buildCalendar(_selectedDate),
        const SizedBox(height: 12),
        // 底部內容依狀態切換
        if (_currentView == ViewState.main) _buildMainView(),
        if (_currentView == ViewState.addRecord) _buildAddRecordView(),
        if (_currentView == ViewState.monthlySummary) _buildMonthlySummaryView(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector 用來監聽點擊空白處，收起鍵盤
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: _buildBodyContent(),
          ),
        ),
      ),
    );
  }
}
