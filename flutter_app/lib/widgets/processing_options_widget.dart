// lib/widgets/processing_options_widget.dart
// A card widget that exposes all processing options to the user.

import 'package:flutter/material.dart';

import '../models/processing_options.dart';

class ProcessingOptionsWidget extends StatefulWidget {
  final ProcessingOptions initial;
  final ValueChanged<ProcessingOptions> onChanged;

  const ProcessingOptionsWidget({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<ProcessingOptionsWidget> createState() =>
      _ProcessingOptionsWidgetState();
}

class _ProcessingOptionsWidgetState extends State<ProcessingOptionsWidget> {
  late ProcessingOptions _opts;

  @override
  void initState() {
    super.initState();
    _opts = widget.initial;
  }

  void _update(ProcessingOptions next) {
    setState(() => _opts = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('處理選項', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // ── Sticker count ───────────────────────────────────────────
            Row(
              children: [
                const Text('貼圖張數：'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _opts.stickerCount,
                  items: kStickerCounts
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c 張'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      _update(_opts.copyWith(stickerCount: v)),
                ),
              ],
            ),

            // ── Padding ─────────────────────────────────────────────────
            Row(
              children: [
                const Text('邊距留白（px）：'),
                Expanded(
                  child: Slider(
                    value: _opts.paddingPx.toDouble(),
                    min: 5,
                    max: 40,
                    divisions: 7,
                    label: '${_opts.paddingPx} px',
                    onChanged: (v) =>
                        _update(_opts.copyWith(paddingPx: v.round())),
                  ),
                ),
                Text('${_opts.paddingPx} px'),
              ],
            ),

            // ── Switches ─────────────────────────────────────────────────
            SwitchListTile(
              title: const Text('AI 自動去背（rembg）'),
              subtitle: const Text('使用 U2-Net 模型去除圖片背景'),
              value: _opts.removeBackground,
              onChanged: (v) =>
                  _update(_opts.copyWith(removeBackground: v)),
            ),
            SwitchListTile(
              title: const Text('自動尺寸調整'),
              subtitle: const Text('自動調整至 LINE 官方規格尺寸並置中'),
              value: _opts.autoProcess,
              onChanged: (v) => _update(_opts.copyWith(autoProcess: v)),
            ),
            SwitchListTile(
              title: const Text('自動壓縮（>1 MB 時）'),
              subtitle: const Text('確保每張圖片符合 1 MB 上限'),
              value: _opts.autoCompress,
              onChanged: (v) =>
                  _update(_opts.copyWith(autoCompress: v)),
            ),
          ],
        ),
      ),
    );
  }
}
