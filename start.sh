#!/bin/bash

# Flutter Reversi Game - 應用啟動腳本
# 用於 VS Code Dev Container

echo "╔════════════════════════════════════════╗"
echo "║  Flutter Reversi Game - 黑白棋        ║"
echo "║  應用啟動腳本                         ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 配置 Flutter 路徑
export PATH="/opt/flutter/flutter/bin:$PATH"

# 檢查 Flutter
echo "✓ 檢查 Flutter..."
flutter --version

echo ""
echo "✓ 啟動本地 HTTP 服務器..."

# 進入 web 目錄
cd /workspaces/Flutter-Python-Teaching-Template/build/web

# 終止舊的服務器
pkill -f "http.server" 2>/dev/null

# 啟動新服務器
python3 -m http.server 8080

