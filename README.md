# Reversi (Othello) - Flutter Web

簡單的 Reversi（黑白棋）遊戲，使用 Flutter Web 開發。這個版本難度很低，適合打發時間：

- 人類玩家先手（黑），電腦為白色，AI 使用簡單的貪婪策略（翻最多子，平手時隨機）。
- 可在本地以瀏覽器執行。

快速啟動（Windows PowerShell）：

```powershell
# 確認已安裝 Flutter 並可使用 web
flutter channel stable
flutter upgrade
flutter config --enable-web

# 在專案根目錄
flutter pub get
flutter run -d chrome
```

若要建立 release build：

```powershell
flutter build web
```

檔案重點：
- `lib/main.dart` - UI 與整體流程
- `lib/game.dart` - 棋盤與遊戲規則邏輯
- `lib/ai.dart` - 簡單 AI 策略
"# Project_2025-1210" 

## 在 GitHub Codespaces/容器環境執行（Flutter Web）
以下步驟假設你在 GitHub Codespaces 或等同的容器環境：

1) 安裝依賴：
```bash
sudo apt-get update && sudo apt-get install -y git curl unzip xz-utils clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

2) 安裝 Flutter stable 並加入 PATH：
```bash
cd /workspaces
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="/workspaces/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

3) 啟用 Web 並檢查環境：
```bash
flutter config --enable-web
flutter doctor
```

4) 回到專案並抓套件：
```bash
cd /workspaces/Flutter-Python-Teaching--
flutter pub get
```

5) 以 Web Server 模式啟動（容器無 Chrome 時使用）：
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```
啟動後終端會顯示可存取的 URL（如 http://0.0.0.0:8080），在 Codespaces 以 Port Forwarding 開啟即可。如果容器/主機有 Chrome，可改用 `flutter run -d chrome`。
