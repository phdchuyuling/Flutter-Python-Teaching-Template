// lib/services/api_service.dart
// Handles all HTTP communication with the Python FastAPI backend.

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/processing_options.dart';

class ApiService {
  // Change this to your backend address when running on a real device / server.
  static const String _baseUrl = 'http://localhost:8000';

  // ── Health check ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> healthCheck() async {
    final resp = await http.get(Uri.parse('$_baseUrl/'));
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ── Process a single image ────────────────────────────────────────────────

  /// Resizes and pads a single image to the given LINE spec type.
  Future<Uint8List> processImage({
    required List<int> imageBytes,
    required String specType, // 'main' | 'sticker' | 'tab'
    int padding = 10,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/process'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'upload.png',
    ));
    request.fields['spec_type'] = specType;
    request.fields['padding'] = padding.toString();

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    _assertOk(resp);
    return resp.bodyBytes;
  }

  // ── Background removal ────────────────────────────────────────────────────

  /// Removes the background of the given image using U2-Net / rembg.
  Future<Uint8List> removeBackground(List<int> imageBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/remove-bg'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'upload.png',
    ));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    _assertOk(resp);
    return resp.bodyBytes;
  }

  // ── Quality pre-check ─────────────────────────────────────────────────────

  Future<CheckResult> checkImage(List<int> imageBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/check'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'upload.png',
    ));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    _assertOk(resp);
    return CheckResult.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  // ── Build ZIP package ─────────────────────────────────────────────────────

  /// Sends all images to the backend and receives a ready-to-upload ZIP.
  Future<Uint8List> buildPackage({
    PickedImage? mainImage,
    List<PickedImage> stickerImages = const [],
    PickedImage? tabImage,
    required ProcessingOptions options,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/package'),
    );

    if (mainImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'main_file',
        mainImage.bytes,
        filename: mainImage.name,
      ));
    }

    for (final sticker in stickerImages) {
      request.files.add(http.MultipartFile.fromBytes(
        'sticker_files',
        sticker.bytes,
        filename: sticker.name,
      ));
    }

    if (tabImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'tab_file',
        tabImage.bytes,
        filename: tabImage.name,
      ));
    }

    request.fields['auto_process'] = options.autoProcess.toString();
    request.fields['compress'] = options.autoCompress.toString();

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    _assertOk(resp);
    return resp.bodyBytes;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertOk(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String detail = resp.body;
      try {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        detail = body['detail']?.toString() ?? detail;
      } catch (_) {}
      throw ApiException(resp.statusCode, detail);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
