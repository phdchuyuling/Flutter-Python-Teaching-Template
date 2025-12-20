#!/bin/bash

# Flutter Web 應用自動執行腳本
set -e

echo "=========================================="
echo "🚀 Flutter 記帳應用 Web 啟動腳本"
echo "=========================================="
echo ""

# 進入專案目錄
cd /workspaces/Flutter-Python-Teaching-Template/bookkeep_new

# 檢查 Flutter
echo "📦 檢查 Flutter 安裝..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安裝"
    echo "請先安裝 Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter 已安裝"
flutter --version
echo ""

# 啟用 Web 支援
echo "🌐 啟用 Web 支援..."
flutter config --enable-web
echo ""

# 清理舊文件
echo "🧹 清理舊的構建文件..."
flutter clean
echo ""

# 獲取依賴
echo "📦 下載依賴包..."
flutter pub get
echo ""

# 檢查可用設備
echo "🔍 檢查可用設備..."
flutter devices
echo ""

# 啟動應用
echo "=========================================="
echo "🚀 啟動應用 (Web Server 模式)"
echo "應用將在 http://localhost:8080 啟動"
echo "按 Ctrl+C 停止服務器"
echo "=========================================="
echo ""

# 使用 web-server 模式啟動（無需 Chrome）
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
