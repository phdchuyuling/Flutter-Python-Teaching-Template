# Flutter 記帳本應用 - 執行與除錯指南

## 📋 概述

這是一個 Flutter 記帳應用，支援在以下平台運行：
- 📱 iOS / Android（原生應用）
- 🌐 Web（瀏覽器）

## 🔧 主要修改（Web 支援）

為了支援 Web 平台，我們做了以下修改：

### 1. **數據庫層更新** (`lib/services/database_service.dart`)
   - 使用條件編譯 (`kIsWeb`) 區分平台
   - Web 平台：使用記憶體存儲（可升級至 IndexedDB）
   - 原生平台：使用 SQLite

### 2. **依賴包更新** (`pubspec.yaml`)
   - 新增 `shared_preferences: ^2.2.2`（用於 Web 存儲）

### 3. **主程式更新** (`lib/main.dart`)
   - 移除重複的 `DatabaseService` 定義
   - 使用外部導入確保代碼單一化

## 🚀 快速執行

### 方式 1：使用執行腳本（推薦）

```bash
chmod +x /workspaces/Flutter-Python-Teaching-Template/run_web.sh
bash /workspaces/Flutter-Python-Teaching-Template/run_web.sh
```

### 方式 2：手動執行

```bash
# 1. 進入專案目錄
cd /workspaces/Flutter-Python-Teaching-Template/bookkeep_new

# 2. 獲取依賴
flutter pub get

# 3. 執行 Web 版本
flutter run -d web
```

### 方式 3：如果 Flutter 未安裝

```bash
# 1. 安裝系統依賴
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils clang cmake ninja-build pkg-config libgtk-3-dev

# 2. 下載並安裝 Flutter
cd ~
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz
export PATH="$HOME/flutter/bin:$PATH"

# 3. 執行應用
cd /workspaces/Flutter-Python-Teaching-Template/bookkeep_new
flutter pub get
flutter run -d web
```

## 🐛 常見問題與除錯

### 問題 1：`flutter: command not found`
**解決方案：**
```bash
export PATH="$HOME/flutter/bin:$PATH"
# 或將以上命令加入 ~/.bashrc
```

### 問題 2：依賴衝突
**解決方案：**
```bash
flutter pub get
flutter pub upgrade
```

### 問題 3：Web 支援未啟用
**解決方案：**
```bash
flutter config --enable-web
```

### 問題 4：構建失敗
**解決方案：**
```bash
flutter clean
flutter pub get
flutter run -d web -v  # -v 用於詳細日誌
```

### 問題 5：端口被佔用
**解決方案：**
```bash
flutter run -d web --web-port 8081  # 使用不同端口
```

## 📊 應用功能

該記帳應用提供以下功能：

1. **記錄管理**
   - 新增收入/支出記錄
   - 刪除記錄
   - 查看記錄列表

2. **數據展示**
   - 按日期排序顯示記錄
   - 統計總收入、總支出、結餘

3. **數據分類**
   - 支援多種分類（工作、購物、飲食等）

## 📁 專案結構

```
bookkeep_new/
├── lib/
│   ├── main.dart                 # 主應用程式
│   ├── home_screen.dart          # 主畫面
│   ├── add_record_screen.dart    # 新增記錄畫面
│   ├── records_list_screen.dart  # 記錄列表畫面
│   ├── models/
│   │   └── record.dart           # 數據模型
│   └── services/
│       └── database_service.dart # 數據庫服務（支援 Web）
├── web/
│   ├── index.html                # Web 入口
│   └── manifest.json
├── pubspec.yaml                  # 依賴配置
└── README.md
```

## ✅ 驗證安裝

運行以下命令驗證環境：

```bash
flutter doctor
```

應該看到：
- ✓ Flutter SDK 已安裝
- ✓ Dart SDK 已安裝
- ✓ Chrome 已安裝（用於 Web 開發）

## 🌐 訪問應用

應用成功啟動後，會自動在瀏覽器打開：
```
http://localhost:8080
```

如果未自動打開，請手動訪問該地址。

## 💾 數據存儲

- **Web 平台**：數據存儲在瀏覽器記憶體中（刷新頁面會丟失）
  - 建議：升級至 IndexedDB 以實現持久化儲存
  
- **原生平台**：數據持久存儲在本地 SQLite 數據庫中

## 🔄 升級建議

為了生產環境使用，建議做以下升級：

1. **Web 持久化儲存**
   ```dart
   // 使用 indexed_db 或 hive 替代記憶體存儲
   import 'package:indexed_db/indexed_db.dart';
   ```

2. **後端 API**
   - 與後端服務器同步數據
   - 實現雲端備份

3. **離線支援**
   - 添加 Service Worker
   - 實現離線優先架構

## 📝 日誌與診斷

詳細執行日誌：
```bash
flutter run -d web -v
```

Flutter 環境診斷：
```bash
flutter doctor -v
```

## ⚙️ 環境變數

如果 Flutter 未在 PATH 中，可以設置：

```bash
export FLUTTER_HOME=$HOME/flutter
export PATH=$FLUTTER_HOME/bin:$PATH
```

## 📞 支援

如有問題，請檢查：
1. Flutter 版本是否最新
2. 系統依賴是否完整
3. 是否有網絡連接（下載依賴需要）

---

祝使用愉快！🎉
