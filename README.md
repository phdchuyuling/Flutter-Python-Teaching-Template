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