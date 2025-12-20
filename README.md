# Flutter Reversi Game - 黑白棋

一個用 Flutter 開發的黑白棋（Reversi/Othello）遊戲，支持與 AI 對戰。

## 🎮 功能特性

- ♟️ **完整的黑白棋遊戲邏輯**
- 🤖 **智能 AI 對手** (5 級難度可調)
- ↩️ **悔棋功能** (Ctrl+Z)
- ⚡ **實時高亮** (顯示 AI 的移動)
- 📱 **響應式 UI 設計**
- 🌐 **跨平台支持** (Web/Desktop)

## 🚀 快速開始

### 方式 1: 使用 VS Code 端口轉發（推薦）⭐

1. **打開命令面板**: Ctrl+Shift+P
2. **運行命令**: `Ports: Expose Port`
3. **輸入端口**: `8080`
4. **點擊端口地址**自動打開瀏覽器

### 方式 2: 從 Terminal 啟動

```bash
cd /workspaces/Flutter-Python-Teaching-Template/build/web
python3 -m http.server 8080
```

然後訪問: **http://10.0.3.48:8080** 或 **http://127.0.0.1:8080**

### 方式 3: 使用啟動腳本

```bash
./start.sh
```

## 📂 項目結構

```
Flutter-Python-Teaching-Template/
├── lib/
│   ├── main.dart           # 主應用程序
│   ├── game.dart           # 遊戲邏輯引擎
│   └── ai.dart             # AI 算法
├── build/web/              # 編譯後的 Web 版本
│   ├── index.html
│   ├── main.dart.js        # 編譯的應用代碼
│   ├── flutter.js          # Flutter 引擎
│   └── canvaskit/          # Canvas 渲染庫
├── pubspec.yaml            # Dart 依賴配置
├── USAGE.md                # 使用指南
└── start.sh                # 快速啟動腳本
```

## 🛠️ 技術棧

- **框架**: Flutter 3.24.0
- **語言**: Dart 3.5.0
- **編譯**: dart2js (JavaScript)
- **渲染**: Canvas + CanvasKit
- **伺服器**: Python 3.12 (SimpleHTTPServer)

## 🎯 遊戲規則

黑白棋是一個經典的策略遊戲，玩家與 AI 輪流放置棋子。

**基本規則**:
- 黑色棋子代表玩家，白色棋子代表 AI
- 放置棋子後，被夾住的對手棋子會被翻轉
- 必須能夠翻轉至少一個對手棋子才能放置
- 遊戲結束時，棋子最多的一方獲勝

**UI 提示**:
- 🟡 **黃色圓點**: 可下的合法位置
- 🔴 **紅色圓圈**: 最後的 AI 移動（會閃爍）

## 🔧 命令參考

### 編譯應用
```bash
export PATH="/opt/flutter/flutter/bin:$PATH"
cd /workspaces/Flutter-Python-Teaching-Template
flutter build web
```

### 開發模式（更快編譯）
```bash
flutter build web --debug
```

### 清理編譯
```bash
flutter clean
flutter build web
```

### 獲取依賴
```bash
flutter pub get
```

## 🐛 疑難排解

### 被防火牆擋住？

**✓ 已解決** - 服務器現在綁定到 0.0.0.0，支持所有網絡介面

嘗試以下 IP 地址：
- `127.0.0.1:8080` - 本地環回
- `10.0.3.48:8080` - 容器 IP ⭐ 推薦
- `172.17.0.1:8080` - Docker 網橋 IP

### 應用無法加載？

1. **檢查服務器**: `ps aux | grep http.server`
2. **驗證文件**: `ls -lh build/web/main.dart.js`
3. **清空快取**: Ctrl+Shift+Del
4. **查看控制台**: F12 -> Console

### 端口被占用？

```bash
pkill -f "http.server"  # 終止舊進程
sleep 2
python3 -m http.server 8080  # 重新啟動
```

## 📚 開發指南

### 修改遊戲邏輯

編輯 `lib/game.dart`:
```dart
// 例如：修改初始棋盤配置
board[3 * boardSize + 3] = -1;  // 白色棋子
```

### 調整 AI 難度

編輯 `lib/ai.dart`:
```dart
int difficulty = 3;  // 1-5, 5 最難
```

### 修改 UI 樣式

編輯 `lib/main.dart`:
```dart
theme: ThemeData(primarySwatch: Colors.blue),  // 修改主題色
```

## 📦 編譯輸出

編譯完成後生成的文件：
- `build/web/index.html` - 主頁面
- `build/web/main.dart.js` - 應用程序代碼 (1.7MB)
- `build/web/flutter.js` - Flutter 引擎
- `build/web/flutter_bootstrap.js` - 啟動代碼
- `build/web/canvaskit/` - 渲染庫

## 🌟 功能演示

### 遊戲界面
- 8x8 棋盤
- 實時得分顯示（黑/白）
- 合法移動指示（黃色圓點）
- AI 移動高亮（閃爍紅圈）

### 控制按鈕
- 🔄 **重新開始** - 新遊戲
- ↩️ **悔棋** - 撤回最後兩步
- ⚙️ **難度調整** - 1-5 級
- ⚡ **速度調整** - 控制 AI 思考時間

## 📝 許可證

此項目為教學用途。

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

---

**開發者**: GitHub Copilot
**最後更新**: 2025-12-20