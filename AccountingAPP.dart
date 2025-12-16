import 'package:flutter/material.dart';
// 匯入 intl 套件，用於日期格式化和本地化
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- 狀態定義 ---
enum ViewState { main, addRecord, monthlySummary }

void main() async {
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
    String numericalText = rawAmountText
        .replaceAll('+', '')
        .replaceAll('-', '');

    // 【修復 2】: 改用 double.tryParse 支援小數點
    final amountValue = double.tryParse(numericalText);

    if (amountValue == null || amountValue <= 0) {
      _showSnackBar(context, '請輸入有效的金額 (例如: 100 或 +1000)');
      return;
    }

    // 儲存有符號的金額：收入為正，支出為負
    // 如果使用者沒打 + 號，預設是支出 (負數)，除非明確打 + 才是收入
    // (這裡保留你原本的邏輯：有+是收入，沒符號看原本邏輯，通常記帳軟體預設是支出)
    // 修正邏輯：如果輸入 +100 -> 收入 (+100)
    // 如果輸入 100 -> 支出 (-100)
    final signedAmount = isIncome ? amountValue : -amountValue;
    final displaySign = isIncome ? '收入' : '支出';

    // 儲存紀錄
    setState(() {
      _records.add({
        "date": _selectedDate,
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
        '成功儲存 $displaySign ($finalCategory)：$amountValue 元！',
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
      final isSelected =
          date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
              // 點擊日期時不強制切回主頁，保留使用者可能正在查看統計的狀態
              // _currentView = ViewState.main;
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
                    // 【修復 3】: 切換月份時，將日期重設為該月 1 號，避免 31 號切到無 31 號的月份時跳號
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('yyyy年MM月').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    // 【修復 3】: 同上
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      1,
                    );
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
                  .map(
                    (day) => SizedBox(
                      width: 24,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  )
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentView = ViewState.main;
                      // 切換回主頁時收起鍵盤
                      FocusScope.of(context).unfocus();
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
                _currentView = ViewState.main;
                FocusScope.of(context).unfocus();
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '新增紀錄',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black87 : Colors.white54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
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
                decoration: InputDecoration(
                  labelText: '自訂項目名稱',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: '例如: 買遊戲',
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white70,
                  isDense: true,
                ),
                style: const TextStyle(color: Colors.black),
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
                backgroundColor: const Color(0xFF6A9B9F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
    final netDisplay = netBalance.abs().toStringAsFixed(
      0,
    ); // 去掉小數點顯示 (如果需要小數可改為 2)
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
                '當月統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Icon(Icons.bar_chart, color: Colors.black),
            ],
          ),
          const SizedBox(height: 15),

          if (filteredRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Text(
                  '本月尚無紀錄。\n快去點擊「新增紀錄」開始記帳吧！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            )
          else ...[
            // 限制高度，如果紀錄太多可以滑動，不會讓介面爆掉
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: filteredRecords.map((record) {
                    final date = record['date'] as DateTime;
                    final category = record['category'] as String;
                    final signedAmount = record['amount'] as double;

                    final isIncome = signedAmount >= 0;
                    final amount = signedAmount.abs().toStringAsFixed(
                      0,
                    ); // 顯示整數
                    final signIcon = isIncome ? '+' : '-';

                    final dateString = DateFormat('MM/dd').format(date);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$dateString $category',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '$signIcon$amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isIncome
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ],
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
                const Text(
                  '總結:',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                Text(
                  '$statusText $netDisplay 元',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentView) {
      case ViewState.main:
        return _buildMainView();
      case ViewState.addRecord:
        return _buildAddRecordView();
      case ViewState.monthlySummary:
        return _buildMonthlySummaryView();
    }
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
            child: Column(
              children: [
                _buildTopNavigation(),
                const SizedBox(height: 20),
                _buildCalendar(_selectedDate),
                const SizedBox(height: 30),
                _buildBodyContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
