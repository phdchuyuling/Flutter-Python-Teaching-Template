# Flutter-Python-Teaching-Template

簡介：這是一個教學用的 Flutter + Python 範本（加上最小可執行的 Reversi 範例）。

## 快速開始（在 devcontainer 中）

1. 在 VS Code 開啟本專案，選擇「Dev Containers: Rebuild and Reopen in Container」。
2. 重建完成後開啟終端機，執行：

   ```bash
   flutter pub get
   dart analyze
   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
   ```

3. 在容器環境中，開啟瀏覽器並前往 `http://localhost:8080`（或 Codespaces 提供的預覽網址）即可看到應用。

---

## 注意事項
- 我已加入最小的 `lib/game.dart` 與 `lib/ai.dart` 作為範例實作，並新增 `.devcontainer` 來方便在容器中執行與測試。
## 本次變更摘要
本次 PR / 提交包含以下主要變更：

- 新增 `lib/game.dart`：最小化的 Reversi（奧賽羅）遊戲邏輯（棋盤、合法走法、下子、悔棋支援與計分）。
- 新增 `lib/ai.dart`：簡單的電腦 AI（依翻轉數與隨機化選擇）。
- 新增 `.devcontainer/`：包含 Dockerfile 與 `devcontainer.json`，用於在容器內安裝 Flutter 並提供 web 開發環境。
- 新增 `pubspec.yaml` 與由 `flutter create` 產生的 `web/` 資料夾（使專案可編譯為 web）。
- 新增 README 的快速啟動說明（如何在 devcontainer 中啟動 web-server）。

若要測試：重建 devcontainer → `flutter pub get` → `dart analyze` → `flutter run -d web-server`，然後開啟 `http://localhost:8080`。

如需我幫忙新增更多說明、測試或針對 AI 做改進，告訴我即可！