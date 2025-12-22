import 'package:flutter/material.dart';

void main() {
  runApp(const BreakfastApp());
}

class BreakfastApp extends StatelessWidget {
  const BreakfastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const BreakfastHomePage(),
    );
  }
}

class Member {
  final String name;
  Member(this.name);
}

class FoodItem {
  final String title;
  final double price;
  final List<String> sharedMembers;

  FoodItem({
    required this.title,
    required this.price,
    required this.sharedMembers,
  });
}

class BreakfastHomePage extends StatefulWidget {
  const BreakfastHomePage({super.key});

  @override
  State<BreakfastHomePage> createState() => _BreakfastHomePageState();
}

class _BreakfastHomePageState extends State<BreakfastHomePage> {
  // 資料儲存
  String storeName = "";
  final List<Member> members = [];
  final List<FoodItem> foodItems = [];

  // 控制器
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final TextEditingController _foodTitleController = TextEditingController();
  final TextEditingController _foodPriceController = TextEditingController();
  
  // 紀錄目前餐點選中的成員
  final Map<String, bool> _selectedMembersForFood = {};

  void _addMember() {
    if (_memberController.text.isNotEmpty) {
      setState(() {
        members.add(Member(_memberController.text));
        _selectedMembersForFood[_memberController.text] = false;
        _memberController.clear();
      });
    }
  }

  void _addFood() {
    final String title = _foodTitleController.text;
    final double? price = double.tryParse(_foodPriceController.text);
    final List<String> selected = _selectedMembersForFood.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    if (title.isNotEmpty && price != null && selected.isNotEmpty) {
      setState(() {
        foodItems.add(FoodItem(
          title: title,
          price: price,
          sharedMembers: selected,
        ));
        _foodTitleController.clear();
        _foodPriceController.clear();
        // 重置勾選狀態
        _selectedMembersForFood.updateAll((key, value) => false);
      });
    }
  }

  double get totalAmount => foodItems.fold(0, (sum, item) => sum + item.price);

  Map<String, double> get memberCosts {
    Map<String, double> costs = {for (var m in members) m.name: 0.0};
    for (var item in foodItems) {
      double splitPrice = item.price / item.sharedMembers.length;
      for (var name in item.sharedMembers) {
        costs[name] = (costs[name] ?? 0) + splitPrice;
      }
    }
    return costs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('早餐紀錄')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【A】早餐店資訊區
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _storeController,
                      decoration: const InputDecoration(labelText: '早餐店名稱'),
                      onChanged: (val) => setState(() => storeName = val),
                    ),
                    const SizedBox(height: 10),
                    Text('目前店名：$storeName', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Divider(),

            // 【B】成員區
            const Text('成員名單', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _memberController, decoration: const InputDecoration(hintText: '輸入成員姓名')),
                ),
                ElevatedButton(onPressed: _addMember, child: const Text('新增成員')),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) => ListTile(title: Text(members[index].name), dense: true),
            ),
            const Divider(),

            // 【C】餐點區
            const Text('新增餐點', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _foodTitleController, decoration: const InputDecoration(labelText: '餐點名稱')),
            TextField(controller: _foodPriceController, decoration: const InputDecoration(labelText: '價格'), keyboardType: TextInputType.number),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('誰吃了這道菜？（需勾選）'),
            ),
            ...members.map((m) => CheckboxListTile(
                  title: Text(m.name),
                  value: _selectedMembersForFood[m.name] ?? false,
                  onChanged: (val) => setState(() => _selectedMembersForFood[m.name] = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                )),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _addFood, child: const Text('新增餐點紀錄')),
            ),
            const SizedBox(height: 10),
            const Text('餐點清單：'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final item = foodItems[index];
                return ListTile(
                  title: Text('${item.title} (\$${item.price})'),
                  subtitle: Text('分攤人: ${item.sharedMembers.join(", ")}'),
                );
              },
            ),
            const Divider(),

            // 【D】花費計算區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('總計金額：\$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  const Text('各成員應付：', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...memberCosts.entries.map((e) => Text('${e.key}: \$${e.value.toStringAsFixed(2)}')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}