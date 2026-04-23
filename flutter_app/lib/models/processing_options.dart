// lib/models/processing_options.dart
// Holds all user-configurable options for the sticker processing pipeline.

/// Allowed numbers of sticker images per LINE spec.
const List<int> kStickerCounts = [8, 16, 24, 32, 40];

/// Processing options selected by the user.
class ProcessingOptions {
  final int stickerCount;
  final bool removeBackground;
  final bool autoProcess;
  final bool autoCompress;
  final int paddingPx;

  const ProcessingOptions({
    this.stickerCount = 8,
    this.removeBackground = false,
    this.autoProcess = true,
    this.autoCompress = true,
    this.paddingPx = 10,
  });

  ProcessingOptions copyWith({
    int? stickerCount,
    bool? removeBackground,
    bool? autoProcess,
    bool? autoCompress,
    int? paddingPx,
  }) {
    return ProcessingOptions(
      stickerCount: stickerCount ?? this.stickerCount,
      removeBackground: removeBackground ?? this.removeBackground,
      autoProcess: autoProcess ?? this.autoProcess,
      autoCompress: autoCompress ?? this.autoCompress,
      paddingPx: paddingPx ?? this.paddingPx,
    );
  }
}

/// Result of a quality pre-check from the backend.
class CheckResult {
  final bool passed;
  final List<String> warnings;
  final List<String> errors;

  const CheckResult({
    required this.passed,
    required this.warnings,
    required this.errors,
  });

  factory CheckResult.fromJson(Map<String, dynamic> json) => CheckResult(
        passed: json['passed'] as bool,
        warnings: List<String>.from(json['warnings'] as List),
        errors: List<String>.from(json['errors'] as List),
      );

  bool get hasIssues => warnings.isNotEmpty || errors.isNotEmpty;
}

/// Wraps a picked image file path & bytes.
class PickedImage {
  final String name;
  final List<int> bytes;

  const PickedImage({required this.name, required this.bytes});
}
