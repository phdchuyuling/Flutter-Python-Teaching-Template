import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/gradient_scaffold.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  final Function(UserProfile) onSave;
  final void Function(double fontScale, Color start, Color end)?
      onAppearanceSave;
  final UserProfile? currentUser;

  const SettingsPage({
    super.key,
    required this.onSave,
    this.onAppearanceSave,
    this.currentUser,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String workLevel = "輕度";
  double _fontScale = 1.0;
  Color _start = const Color(0xFF4FACFE);
  Color _end = const Color(0xFF00F2FE);
  final Map<String, double> _fontOptions = {'小': 0.9, '中': 1.0, '大': 1.2};
  String _selectedFontLabel = '中';
  final Map<String, List<Color>> _palette = {
    '藍系': [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
    '暖系': [const Color(0xFFFFB86B), const Color(0xFFFF6B6B)],
    '綠系': [const Color(0xFF00C9A7), const Color(0xFF00E4FF)],
  };
  String _selectedPalette = '藍系';

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text("設定")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _heightCtrl,
              decoration: const InputDecoration(labelText: "身高(cm)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _weightCtrl,
              decoration: const InputDecoration(labelText: "體重(kg)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _ageCtrl,
              decoration: const InputDecoration(labelText: "年齡"),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: workLevel,
              items: const [
                DropdownMenuItem(value: "輕度", child: Text("輕度工作")),
                DropdownMenuItem(value: "中度", child: Text("中度工作")),
                DropdownMenuItem(value: "重度", child: Text("重度工作")),
              ],
              onChanged: (v) {
                if (v != null) setState(() => workLevel = v);
              },
            ),
            const SizedBox(height: 12),
            // Appearance options
            Row(children: [
              const Text('字體大小：'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedFontLabel,
                items: _fontOptions.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) {
                  if (v != null)
                    setState(() {
                      _selectedFontLabel = v;
                      _fontScale = _fontOptions[v]!;
                    });
                },
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Text('主題色：'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedPalette,
                items: _palette.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) {
                  if (v != null)
                    setState(() {
                      _selectedPalette = v;
                      _start = _palette[v]![0];
                      _end = _palette[v]![1];
                    });
                },
              ),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final user = UserProfile(
                  height: double.tryParse(_heightCtrl.text) ?? 170,
                  weight: double.tryParse(_weightCtrl.text) ?? 60,
                  age: int.tryParse(_ageCtrl.text) ?? 25,
                  workLevel: workLevel,
                );
                widget.onSave(user);
                if (widget.onAppearanceSave != null) {
                  widget.onAppearanceSave!(_fontScale, _start, _end);
                }
              },
              child: const Text("儲存"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // initialize appearance controls from current app values
    _fontScale = appFontScale;
    _selectedFontLabel = _fontOptions.entries
        .firstWhere((e) => e.value == _fontScale,
            orElse: () => const MapEntry('中', 1.0))
        .key;
    // find palette matching current colors
    final match = _palette.entries.firstWhere(
        (e) => e.value[0] == c1Start && e.value[1] == c1End,
        orElse: () => _palette.entries.first);
    _selectedPalette = match.key;
    _start = match.value[0];
    _end = match.value[1];
    // initialize user-related fields from provided currentUser (if any)
    if (widget.currentUser != null) {
      final u = widget.currentUser!;
      _heightCtrl.text = u.height.toString();
      _weightCtrl.text = u.weight.toString();
      _ageCtrl.text = u.age.toString();
      workLevel = u.workLevel;
    }
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }
}
