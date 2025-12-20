# Flutter Reversi 應用 - 使用指南

## 應用訪問方式

### 方式 1: 使用 VS Code 端口轉發（推薦）

1. **打開命令面板** (Ctrl+Shift+P)
2. 搜索並運行: `Ports: Expose Port`
3. 輸入端口號: `8080`
4. 右鍵點擊端口 8080，選擇 `Open in Browser`

### 方式 2: 直接訪問 Container IP

在主機瀏覽器中訪問:
```
http://10.0.3.48:8080
```

### 方式 3: 使用本地主機轉發

在 dev container 中運行:
```bash
python3 -m http.server 8080
```

然後在主機中訪問:
```
http://localhost:8080
```

## 啟動服務器

### 方法 1: 使用啟動腳本
```bash
./start.sh
```

### 方法 2: 手動啟動
```bash
cd /workspaces/Flutter-Python-Teaching-Template/build/web
python3 -m http.server 8080
```

## 遊戲功能

- 🎮 **黑白棋遊戲** (Reversi/Othello)
- 🤖 **AI 對手** (5 級難度)
- ↩️ **悔棋** (Ctrl+Z)
- ⚡ **實時高亮** (AI 移動)
- 📱 **響應式設計**

## 疑難排解

### 被防火牆擋住?

嘗試以下步驟:

1. **檢查服務器狀態**
   ```bash
   ps aux | grep http.server
   ```

2. **驗證端口開放**
   ```bash
   ss -tuln | grep 8080
   ```

3. **測試連線**
   ```bash
   curl http://10.0.3.48:8080
   ```

4. **使用其他 IP**
   - `127.0.0.1` (本地環回)
   - `10.0.3.48` (容器 IP)
   - `172.17.0.1` (Docker 網橋 IP)

### 應用無法加載?

- 確保 `main.dart.js` 文件存在 (1.7MB)
- 清空瀏覽器快取 (Ctrl+Shift+Del)
- 檢查瀏覽器控制台有無錯誤 (F12)

## 技術棧

- **框架**: Flutter 3.24.0
- **語言**: Dart 3.5.0
- **編譯目標**: JavaScript (dart2js)
- **前端**: HTML5 + Canvas (CanvasKit)
- **伺服器**: Python SimpleHTTPServer

## 開發建議

1. 修改 Dart 代碼後，重新編譯:
   ```bash
   flutter build web
   ```

2. 使用開發模式 (更快編譯):
   ```bash
   flutter build web --debug
   ```

3. 監視文件變化:
   ```bash
   flutter pub get
   ```

## 相關文件

- **主程序**: `lib/main.dart`
- **遊戲邏輯**: `lib/game.dart`
- **AI 邏輯**: `lib/ai.dart`
- **配置**: `pubspec.yaml`
- **編譯輸出**: `build/web/`
