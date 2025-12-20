import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CurrencyConverterPage(),
    );
  }
}

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final TextEditingController _amountController = TextEditingController(text: '1');
  // 幣別清單會由台灣銀行網頁解析取得
  List<String> _currencies = ['TWD'];
  // 預設從台幣輸入
  String _from = 'TWD';
  // 預設目標也設為 TWD，避免 dropdown 初始時 value 不在 items 中造成錯誤
  String _to = 'TWD';
  String? _resultText;
  bool _loading = false;
  // 若無法抓取台灣銀行頁面，可使用 exchangerate.host 作為 fallback
  bool _useFallback = false;

  // 解析自台灣銀行的匯率資料
  // _rates[currency] = { 'spotBuy': double?, 'spotSell': double? }
  Map<String, Map<String, double>> _rates = {};
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    // 啟動時嘗試抓取台灣銀行匯率；若失敗，啟用 fallback
    _fetchRatesFromBOT().catchError((e) {
      setState(() {
        _useFallback = true;
      });
      // 不顯示錯誤在啟動時（避免打擾使用者），但記錄 lastUpdated as null
    });
  }

  Future<void> _convert() async {
    final input = _amountController.text.trim();
    final amount = double.tryParse(input);
    if (amount == null) {
      setState(() {
        _resultText = '請輸入有效數字';
      });
      return;
    }

    setState(() {
      _loading = true;
      _resultText = null;
    });

    try {
      if (_from == _to) {
        setState(() {
          _resultText = '${NumberFormat('#,##0.00').format(amount)} $_from = ${NumberFormat('#,##0.00').format(amount)} $_to';
        });
        return;
      }

      // 確保已經有匯率資料；若抓取台灣銀行失敗並啟用 fallback，改用 exchangerate.host 的 convert API
      if (_rates.isEmpty && !_useFallback) {
        try {
          await _fetchRatesFromBOT();
        } catch (e) {
          // 啟用 fallback
          _useFallback = true;
        }
      }

      double computeResult = 0;

      double? getSpotBuy(String cur) => _rates[cur]?['spotBuy'];
      double? getSpotSell(String cur) => _rates[cur]?['spotSell'];

      if (_useFallback) {
        // 使用 exchangerate.host 的 convert endpoint 作為 fallback（支援跨幣別轉換）
        final conv = await _convertViaExchangeHost(amount, _from, _to);
        final f = NumberFormat('#,##0.00');
        setState(() {
          _resultText = '${f.format(amount)} $_from = ${f.format(conv)} $_to';
        });
        return;
      }

      if (_from == 'TWD') {
        // TWD -> 外幣：使用銀行的「即期賣出」(bank sells foreign)，用 TWD / sell
        final sell = getSpotSell(_to);
        if (sell == null || sell == 0) throw '無 ${_to} 匯率資料';
        computeResult = amount / sell;
      } else if (_to == 'TWD') {
        // 外幣 -> TWD：使用銀行的「即期買入」(bank buys foreign)，用 foreign * buy
        final buy = getSpotBuy(_from);
        if (buy == null) throw '無 ${_from} 匯率資料';
        computeResult = amount * buy;
      } else {
        // 外幣 -> 外幣：先 foreign1 -> TWD (using buy), 然後 TWD -> foreign2 (using sell)
        final buy = getSpotBuy(_from);
        final sell = getSpotSell(_to);
        if (buy == null) throw '無 ${_from} 匯率資料';
        if (sell == null || sell == 0) throw '無 ${_to} 匯率資料';
        final twd = amount * buy;
        computeResult = twd / sell;
      }

      final f = NumberFormat('#,##0.00');
      setState(() {
        _resultText = '${f.format(amount)} $_from = ${f.format(computeResult)} $_to';
      });
    } catch (e) {
      setState(() {
        _resultText = '轉換失敗：$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // fallback：使用 exchangerate.host 的 convert endpoint
  Future<double> _convertViaExchangeHost(double amount, String from, String to) async {
    final original = 'https://api.exchangerate.host/convert?from=$from&to=$to&amount=$amount';
    // 在 Web 環境或直接請求失敗（例如被 Cloudflare 阻擋）時，改用 AllOrigins 代理以繞過 CORS/封鎖
    Future<double> parseResponse(http.Response res) async {
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final num? result = data['result'];
        if (result != null) return result.toDouble();
        throw 'fallback API 無回傳結果';
      } else {
        throw 'fallback API error ${res.statusCode}';
      }
    }

    // 先嘗試直接呼叫 exchangerate.host（在 web 環境可能會被封鎖）
    try {
      if (!kIsWeb) {
        final uri = Uri.parse(original);
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        try {
          return await parseResponse(res);
        } catch (e) {
          // 若 API 回傳錯誤（例如需要 access key），繼續走代理或替代 API
        }
      }

      // 嘗試使用 AllOrigins 代理（繞過 CORS / Cloudflare）
      final proxy = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(original)}';
      final uri = Uri.parse(proxy);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      try {
        return await parseResponse(res);
      } catch (e) {
        // 若仍失敗（exchangerate.host 已改為需要 API key），改用替代的免費匯率 API
      }
    } catch (_) {
      // ignore and try alternative
    }

    // 替代 API：open.er-api.com（回傳以 base 為所請求貨幣的 rates）
    try {
      final alt = 'https://open.er-api.com/v6/latest/${Uri.encodeComponent(from)}';
      final uriAlt = Uri.parse(alt);
      final resAlt = await http.get(uriAlt).timeout(const Duration(seconds: 10));
      if (resAlt.statusCode == 200) {
        final data = json.decode(resAlt.body) as Map<String, dynamic>;
        // 範例回傳會有 "result":"success" 與 "rates" map
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null && rates.containsKey(to)) {
          final v = rates[to];
          if (v is num) return amount * v.toDouble();
          if (v is String) {
            final parsed = double.tryParse(v);
            if (parsed != null) return amount * parsed;
          }
        }
      }
      throw '替代 API 無法取得 ${from}->${to} 匯率';
    } catch (e) {
      throw 'fallback API 都失敗：$e';
    }
  }

  // 解析台灣銀行網頁，取得即期匯率
  Future<void> _fetchRatesFromBOT() async {
    final original = 'https://rate.bot.com.tw/xrt?Lang=zh-TW';
    Uri uri = Uri.parse(original);
    // 在 Web 瀏覽器裡可能會遇到 CORS 限制，嘗試使用 AllOrigins 代理作為 fallback
    if (kIsWeb) {
      final proxy = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(original)}';
      uri = Uri.parse(proxy);
    }
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw '無法取得資料（HTTP ${res.statusCode}）';

      final doc = html_parser.parse(res.body);
      final rows = doc.querySelectorAll('table.table tbody tr');
      final Map<String, Map<String, double>> map = {};

      for (final row in rows) {
        final tds = row.querySelectorAll('td');
        if (tds.length < 5) continue;

        // 幣別欄位可能包含中文名稱與三碼（例如：美金 USD）
        final codeMatch = RegExp(r'([A-Z]{3})').firstMatch(tds[0].text);
        if (codeMatch == null) continue;
        final code = codeMatch.group(1)!.trim();

        double? parseRate(String s) {
          final cleaned = s.replaceAll(',', '').replaceAll('--', '').trim();
          if (cleaned.isEmpty) return null;
          return double.tryParse(cleaned);
        }

        final cashBuy = parseRate(tds[1].text);
        final cashSell = parseRate(tds[2].text);
        final spotBuy = parseRate(tds[3].text);
        final spotSell = parseRate(tds[4].text);

        map[code] = {
          if (spotBuy != null) 'spotBuy': spotBuy,
          if (spotSell != null) 'spotSell': spotSell,
        };
      }

      setState(() {
        _rates = map;
        // 重建幣別清單（保證包含 TWD）
        final codes = map.keys.toList()..sort();
        _currencies = ['TWD', ...codes];
        // 若目前選擇的幣別不存在於新清單，重設為第一個
        if (!_currencies.contains(_from)) _from = 'TWD';
        if (!_currencies.contains(_to)) _to = _currencies.length > 1 ? _currencies[1] : 'TWD';
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      throw '抓取台灣銀行匯率失敗：$e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('匯率兌換器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金額',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // 幣別尚未載入時顯示 loading 並 disable controls，避免 dropdown value 不在 items 中導致崩潰
            if (_currencies.length <= 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('載入幣別中...')
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildCurrencyDropdownWithLabel('來源幣別', _from, (v) => setState(() => _from = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCurrencyDropdownWithLabel('目標幣別', _to, (v) => setState(() => _to = v!))),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_loading || _currencies.length <= 1) ? null : _convert,
                    child: _loading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('兌換'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() {
                            _loading = true;
                            _resultText = null;
                          });
                          try {
                            await _fetchRatesFromBOT();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新台灣銀行匯率')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失敗：$e')));
                          } finally {
                            setState(() {
                              _loading = false;
                            });
                          }
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('更新匯率'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_resultText != null)
              Text(
                _resultText!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            if (_lastUpdated != null)
              Text('最後更新：${DateFormat('yyyy-MM-dd HH:mm').format(_lastUpdated!)}', style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Text(
              _useFallback
                  ? '匯率資料來源：exchangerate.host（fallback）'
                  : '匯率資料來源：台灣銀行（即期）',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdownWithLabel(String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}




