import '../models/record.dart';

/// 統一的數據庫服務（支援 Web 和原生平台）
/// Web: 使用記憶體存儲
/// 原生: 可升級為 SQLite (當前使用記憶體存儲以保持兼容)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static final List<Map<String, dynamic>> _data = [];

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// 插入記錄
  Future<int> insertRecord(Record record) async {
    int newId = _data.isEmpty 
        ? 1 
        : (_data.fold<int>(0, (max, item) => item['id'] > max ? item['id'] : max) + 1);
    
    final recordMap = record.toMap();
    recordMap['id'] = newId;
    _data.add(recordMap);
    
    return newId;
  }

  /// 獲取所有記錄
  Future<List<Record>> getRecords() async {
    final sortedData = List<Map<String, dynamic>>.from(_data);
    sortedData.sort((a, b) => 
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    
    return List.generate(
        sortedData.length, (i) => Record.fromMap(sortedData[i]));
  }

  /// 刪除記錄
  Future<int> deleteRecord(int id) async {
    final initialLength = _data.length;
    _data.removeWhere((item) => item['id'] == id);
    return initialLength - _data.length; // 返回刪除數量
  }

  /// 獲取統計數據
  Future<Map<String, double>> getStatistics() async {
    final records = await getRecords();
    double totalIncome = 0;
    double totalExpense = 0;

    for (var record in records) {
      if (record.type == 'income') {
        totalIncome += record.amount;
      } else {
        totalExpense += record.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  /// 清除所有數據（用於測試）
  Future<void> clearAll() async {
    _data.clear();
  }

  /// 獲取記錄總數
  Future<int> getRecordCount() async {
    return _data.length;
  }
}
