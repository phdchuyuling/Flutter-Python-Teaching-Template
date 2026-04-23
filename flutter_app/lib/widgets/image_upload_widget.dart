// lib/widgets/image_upload_widget.dart
// A reusable card widget for picking and previewing a single image slot.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/processing_options.dart';

class ImageUploadWidget extends StatefulWidget {
  /// Display label for this slot (e.g. "主要圖片", "標籤圖片").
  final String label;

  /// Expected LINE spec size hint shown to the user.
  final String sizeHint;

  /// Called when the user picks a file.
  final ValueChanged<PickedImage?> onImagePicked;

  /// Whether this slot is required.
  final bool required;

  const ImageUploadWidget({
    super.key,
    required this.label,
    required this.sizeHint,
    required this.onImagePicked,
    this.required = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  Uint8List? _previewBytes;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _previewBytes = file.bytes!;
      _fileName = file.name;
    });

    widget.onImagePicked(
      PickedImage(name: file.name, bytes: file.bytes!),
    );
  }

  void _clear() {
    setState(() {
      _previewBytes = null;
      _fileName = null;
    });
    widget.onImagePicked(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: theme.textTheme.labelLarge,
                  ),
                  if (widget.required)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '必選',
                        style: TextStyle(
                            fontSize: 11, color: color.onErrorContainer),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.sizeHint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color.outline),
              ),
              const SizedBox(height: 8),

              // Preview or placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: color.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: color.surfaceContainerHighest,
                ),
                child: _previewBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(
                          _previewBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 36, color: color.primary),
                          const SizedBox(height: 4),
                          Text('點擊上傳',
                              style: TextStyle(
                                  fontSize: 12, color: color.primary)),
                        ],
                      ),
              ),

              // File name & clear button
              if (_fileName != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _fileName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: _clear,
                      tooltip: '移除',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
