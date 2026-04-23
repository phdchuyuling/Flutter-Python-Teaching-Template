# Flutter-Python-Teaching-Template

# 自動化 LINE 貼圖裁切與規格處理系統

一個結合 **Python FastAPI 後端**與 **Flutter 前端**的全端專題，示範如何將電腦視覺、AI 去背、自動化腳本整合成完整的使用者應用程式。

---

## 📂 專案結構

```
.
├── python_backend/          # Python FastAPI 後端
│   ├── main.py              # REST API 伺服器入口
│   ├── image_processor.py   # 核心圖像處理模組
│   ├── background_remover.py# AI 去背模組（rembg / U2-Net）
│   ├── quality_checker.py   # 品質預檢模組
│   ├── packager.py          # ZIP 打包模組
│   ├── requirements.txt     # Python 依賴套件
│   └── tests/               # pytest 單元測試
└── flutter_app/             # Flutter 前端
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── models/          # 資料模型
        ├── screens/         # UI 頁面
        ├── widgets/         # 可複用元件
        └── services/        # API 通訊服務
```

---

## 🚀 快速開始

### 1. 啟動 Python 後端

```bash
cd python_backend

# 安裝依賴套件
pip install -r requirements.txt

# 啟動 FastAPI 伺服器
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

API 互動文件（Swagger UI）：[http://localhost:8000/docs](http://localhost:8000/docs)

### 2. 執行 Flutter 前端

```bash
cd flutter_app
flutter pub get
flutter run
```

> **注意**：若要在手機或模擬器上執行，請將 `flutter_app/lib/services/api_service.dart` 中的 `_baseUrl` 改為後端主機的實際 IP 位址。

---

## ✨ 功能模組說明

### 1. 自動化尺寸調整與規格校驗（`image_processor.py`）

| 圖片類型 | 規格尺寸 |
|---------|---------|
| 主要圖片 (Main) | 240 × 240 px |
| 貼圖圖片 (Sticker) | 最大 370 × 320 px |
| 標籤圖片 (Tab) | 96 × 74 px |

- `ensure_even_dimension(value)` — 確保尺寸為偶數（LINE 官方要求）
- 輸出格式：PNG，透明背景（RGBA），解析度 72 dpi 以上

### 2. 智慧型邊距與留白處理

- 使用 OpenCV 偵測「非透明像素」的邊界框（Bounding Box）
- 自動按比例縮放，確保圖案外緣距畫布邊緣至少 10px
- **重心對齊演算法**：計算內容重心，將圖案置中於畫布

### 3. AI 自動去背（`background_remover.py`）

- 整合 [rembg](https://github.com/danielgatis/rembg)（U2-Net 深度學習模型）
- 一鍵去除背景，輸出透明背景 PNG
- 模組採延遲載入，未安裝 rembg 時其餘功能仍可正常運作

### 4. 品質預檢系統（`quality_checker.py`）

| 檢查項目 | 說明 |
|---------|------|
| 長寬比偵測 | 長寬比 < 0.25 或 > 4.0 時警告 |
| 色彩平衡偵測 | 非透明像素平均亮度 > 200/255 時警告 |
| 透明度檢查 | 圖片不含透明通道或透明像素時警告 |
| 內容比例檢查 | 有效像素低於畫布 2% 時警告 |

### 5. 自動打包（`packager.py`）

- 依 LINE 官方命名規範自動重新命名：`main.png`、`sticker01.png` … `tab.png`
- 自動壓縮超過 1 MB 的圖片（在維持 72 dpi 品質前提下）
- 監控 ZIP 總大小，超過 60 MB 時警告

---

## 🔌 API 端點

| 方法 | 路徑 | 說明 |
|------|------|------|
| GET | `/` | 健康檢查 |
| POST | `/process` | 單張圖片尺寸調整與置中 |
| POST | `/remove-bg` | AI 自動去背 |
| POST | `/check` | 品質預檢（回傳 JSON） |
| POST | `/package` | 批次處理並打包 ZIP |

---

## 🧪 執行測試

```bash
cd python_backend
python -m pytest tests/ -v
```

共 32 個單元測試，涵蓋所有核心模組。

---

## 📦 依賴套件

### Python 後端
- `fastapi` — REST API 框架
- `uvicorn` — ASGI 伺服器
- `Pillow` — 圖像處理
- `opencv-python-headless` — 邊界框偵測
- `numpy` — 數值計算
- `rembg` — AI 去背（可選）

### Flutter 前端
- `http` — API 通訊
- `file_picker` — 圖片選擇
- `provider` — 狀態管理
- `path_provider` + `share_plus` — 檔案儲存與分享
