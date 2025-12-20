import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../services/database_service.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({Key? key}) : super(key: key);

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Record> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _dbService.getRecords();
    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('所有記錄'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _records.isEmpty
          ? const Center(
              child: Text('尚無記錄', style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return _buildRecordCard(record);
              },
            ),
    );
  }

  Widget _buildRecordCard(Record record) {
    final isIncome = record.type == 'income';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green : Colors.red,
          child: Icon(
            isIncome ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(
          record.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('yyyy-MM-dd').format(record.date)),
            if (record.note != null) Text(record.note!),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${record.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            Text(
              isIncome ? '收入' : '支出',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(record),
      ),
    );
  }

  Future<void> _showDeleteDialog(Record record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除記錄'),
        content: const Text('確定要刪除這筆記錄嗎?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true && record.id != null) {
      await _dbService.deleteRecord(record.id!);
      _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記錄已刪除')),
        );
      }
    }
  }
}
