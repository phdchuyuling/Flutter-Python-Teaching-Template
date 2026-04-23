// lib/main.dart
// Entry point for the LINE Sticker Processing System Flutter app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const LineStickerApp());
}

class LineStickerApp extends StatelessWidget {
  const LineStickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'LINE 貼圖處理系統',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00B900), // LINE green
          ),
          useMaterial3: true,
          fontFamily: 'sans-serif',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
