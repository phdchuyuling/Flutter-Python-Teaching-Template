import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'add_record_screen.dart';
import 'records_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, double> _statistics = {
    'income': 0,
    'expense': 0,
    'balance': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await _dbService.getStatistics();
    setState(() {
      _statistics = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('記帳本'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatisticsCard(),
                const SizedBox(height: 20),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecordScreen()),
          );
          _loadStatistics();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              '財務概況',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildStatRow('收入', _statistics['income']!, Colors.green),
            const SizedBox(height: 10),
            _buildStatRow('支出', _statistics['expense']!, Colors.red),
            const Divider(height: 30),
            _buildStatRow('餘額', _statistics['balance']!, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecordsListScreen()),
              );
              _loadStatistics();
            },
            icon: const Icon(Icons.list),
            label: const Text('查看所有記錄'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
