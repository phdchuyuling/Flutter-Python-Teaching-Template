import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../services/database_service.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({Key? key}) : super(key: key);

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  String _type = 'expense';
  String _category = '餐飲';
  DateTime _selectedDate = DateTime.now();

  final List<String> _expenseCategories = ['餐飲', '交通', '購物', '娛樂', '其他'];
  final List<String> _incomeCategories = ['薪水', '獎金', '投資', '其他'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增記錄'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              _buildCategorySelector(),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildNoteField(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('支出'),
                value: 'expense',
                groupValue: _type,
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                    _category = _expenseCategories[0];
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('收入'),
                value: 'income',
                groupValue: _type,
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                    _category = _incomeCategories[0];
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '金額',
        prefixText: '\$ ',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請輸入金額';
        }
        if (double.tryParse(value) == null) {
          return '請輸入有效的數字';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = _type == 'expense' ? _expenseCategories : _incomeCategories;
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(
        labelText: '類別',
        border: OutlineInputBorder(),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _category = value!;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '日期',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: '備註 (選填)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveRecord,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: const Text('儲存', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final record = Record(
        type: _type,
        amount: double.parse(_amountController.text),
        category: _category,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
      );

      await _dbService.insertRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記錄已儲存')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
