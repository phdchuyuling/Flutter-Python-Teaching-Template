// lib/screens/home_screen.dart
// Main screen of the LINE Sticker Processing System.
//
// Sections:
// 1. Image upload (main, stickers, tab)
// 2. Processing options
// 3. Quality pre-check results
// 4. Package & Download actions

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/processing_options.dart';
import '../services/api_service.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/processing_options_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State ──────────────────────────────────────────────────────────────
  PickedImage? _mainImage;
  PickedImage? _tabImage;
  final List<PickedImage> _stickerImages = [];
  ProcessingOptions _options = const ProcessingOptions();

  bool _isLoading = false;
  String? _statusMessage;
  List<String> _checkWarnings = [];
  List<String> _checkErrors = [];

  // ── Helpers ────────────────────────────────────────────────────────────
  ApiService get _api => context.read<ApiService>();

  void _setStatus(String msg) =>
      setState(() => _statusMessage = msg);

  void _setLoading(bool v) => setState(() => _isLoading = v);

  // ── Sticker batch picker ───────────────────────────────────────────────

  Future<void> _pickStickerBatch() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    final picked = result.files
        .where((f) => f.bytes != null)
        .map((f) => PickedImage(name: f.name, bytes: f.bytes!))
        .toList();

    if (picked.isEmpty) return;

    // Enforce sticker count limit
    final target = _options.stickerCount;
    setState(() {
      _stickerImages.clear();
      _stickerImages.addAll(picked.take(target));
    });

    _setStatus(
        '已選取 ${_stickerImages.length} 張貼圖（目標 $target 張）。');
  }

  // ── Quality pre-check ──────────────────────────────────────────────────

  Future<void> _runQualityCheck() async {
    final images = [
      if (_mainImage != null) _mainImage!,
      ..._stickerImages.take(1), // check first sticker as representative
      if (_tabImage != null) _tabImage!,
    ];
    if (images.isEmpty) {
      _showSnack('請先上傳至少一張圖片再執行預檢。');
      return;
    }

    _setLoading(true);
    _setStatus('正在執行品質預檢…');
    setState(() {
      _checkWarnings.clear();
      _checkErrors.clear();
    });

    try {
      for (final img in images) {
        final result = await _api.checkImage(img.bytes);
        setState(() {
          _checkWarnings.addAll(result.warnings);
          _checkErrors.addAll(result.errors);
        });
      }
      _setStatus('預檢完成。');
    } on ApiException catch (e) {
      _setStatus('預檢失敗：${e.message}');
    } finally {
      _setLoading(false);
    }
  }

  // ── Package & download ─────────────────────────────────────────────────

  Future<void> _buildAndDownload() async {
    if (_mainImage == null &&
        _stickerImages.isEmpty &&
        _tabImage == null) {
      _showSnack('請先上傳圖片。');
      return;
    }

    _setLoading(true);
    _setStatus('正在處理並打包圖片…');

    try {
      // Optional: remove background first
      PickedImage? processedMain = _mainImage;
      final processedStickers = List<PickedImage>.from(_stickerImages);
      PickedImage? processedTab = _tabImage;

      if (_options.removeBackground) {
        _setStatus('AI 去背中（主要圖片）…');
        if (_mainImage != null) {
          final bg = await _api.removeBackground(_mainImage!.bytes);
          processedMain = PickedImage(name: _mainImage!.name, bytes: bg);
        }
        for (int i = 0; i < processedStickers.length; i++) {
          _setStatus('AI 去背中（貼圖 ${i + 1}/${processedStickers.length}）…');
          final bg = await _api.removeBackground(processedStickers[i].bytes);
          processedStickers[i] =
              PickedImage(name: processedStickers[i].name, bytes: bg);
        }
        if (_tabImage != null) {
          _setStatus('AI 去背中（標籤圖片）…');
          final bg = await _api.removeBackground(_tabImage!.bytes);
          processedTab = PickedImage(name: _tabImage!.name, bytes: bg);
        }
      }

      _setStatus('正在打包 ZIP…');
      final zipBytes = await _api.buildPackage(
        mainImage: processedMain,
        stickerImages: processedStickers,
        tabImage: processedTab,
        options: _options,
      );

      await _saveZip(zipBytes);
      _setStatus('✅ ZIP 已下載！共 ${processedStickers.length + (processedMain != null ? 1 : 0) + (processedTab != null ? 1 : 0)} 張圖片。');
    } on ApiException catch (e) {
      _setStatus('❌ 錯誤：${e.message}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveZip(Uint8List bytes) async {
    if (kIsWeb) {
      // Web: use share_plus or browser download trigger
      _showSnack('Web 平台請使用瀏覽器另存功能。');
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/line_stickers.zip');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'LINE 貼圖 ZIP'),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LINE 貼圖處理系統'),
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '關於',
            onPressed: _showAbout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? '處理中…'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Status banner ────────────────────────────────────
                  if (_statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _statusMessage!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: color.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // ── Section: Required images ─────────────────────────
                  _sectionTitle('必要圖片'),
                  Row(
                    children: [
                      Expanded(
                        child: ImageUploadWidget(
                          label: '主要圖片',
                          sizeHint: '240 × 240 px',
                          required: true,
                          onImagePicked: (img) =>
                              setState(() => _mainImage = img),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ImageUploadWidget(
                          label: '標籤圖片',
                          sizeHint: '96 × 74 px',
                          required: true,
                          onImagePicked: (img) =>
                              setState(() => _tabImage = img),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Section: Sticker images ──────────────────────────
                  _sectionTitle(
                      '貼圖圖片（${_stickerImages.length}/${_options.stickerCount} 張）'),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                        '選取最多 ${_options.stickerCount} 張貼圖圖片'),
                    onPressed: _pickStickerBatch,
                  ),
                  if (_stickerImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _stickerImages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                Uint8List.fromList(
                                    _stickerImages[i].bytes),
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _stickerImages.removeAt(i)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close,
                                      size: 16,
                                      color: color.onError),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Section: Options ─────────────────────────────────
                  ProcessingOptionsWidget(
                    initial: _options,
                    onChanged: (opts) =>
                        setState(() => _options = opts),
                  ),

                  const SizedBox(height: 16),

                  // ── Section: Quality check results ───────────────────
                  if (_checkWarnings.isNotEmpty ||
                      _checkErrors.isNotEmpty) ...[
                    _sectionTitle('品質預檢結果'),
                    ..._checkErrors.map((e) => _issueRow(
                        e, Icons.error, color.error)),
                    ..._checkWarnings.map((w) => _issueRow(
                        w, Icons.warning_amber, color.tertiary)),
                    const SizedBox(height: 8),
                  ],

                  // ── Action buttons ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('品質預檢'),
                          onPressed: _runQualityCheck,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('打包下載 ZIP'),
                          onPressed: _buildAndDownload,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _issueRow(String text, IconData icon, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'LINE 貼圖處理系統',
      applicationVersion: '1.0.0',
      children: const [
        Text('自動化 LINE 貼圖裁切與規格處理系統\n'
            '整合 AI 去背（U2-Net/rembg）、智慧留白、品質預檢、自動打包功能。'),
      ],
    );
  }
}
