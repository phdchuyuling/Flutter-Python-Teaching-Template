# Flutter-Python-Teaching-Template

## 🎓 教學專用模板 (Teaching Template)

這是一個為學生設計的教學模板，包含自動提醒功能，幫助學生記得提交和推送他們的程式碼。

This is a teaching template designed for students, with automatic reminders to help students remember to commit and push their code.

## ✨ 功能特色 (Features)

### 📢 自動 Git Push 提醒 (Automatic Git Push Reminder)

在 GitHub Codespaces 中工作時，系統會自動檢查您的 Git 狀態：

When working in GitHub Codespaces, the system automatically checks your Git status:

- ⚠️ **未提交的更改 (Uncommitted Changes)**: 當您修改了檔案但還沒有 commit，會顯示明顯的警告訊息
- ⚠️ **未推送的提交 (Unpushed Commits)**: 當您已經 commit 但還沒有 push，會提醒您執行 `git push`

## 🚀 開始使用 (Getting Started)

### 在 GitHub Codespaces 中使用 (Using with GitHub Codespaces)

1. 點擊 **Code** 按鈕，選擇 **Codespaces**
2. 建立新的 Codespace 或開啟現有的 Codespace
3. 系統會自動安裝 Git 提醒功能
4. 開始編輯檔案！當您有未提交或未推送的更改時，會看到提醒訊息

### 提醒訊息範例 (Reminder Examples)

當您有未提交的更改時：
```
⚠️  WARNING: You have UNCOMMITTED changes! 您有未提交的更改！
   Please run: git add . && git commit -m 'your message'
```

當您有未推送的提交時：
```
⚠️  WARNING: You have UNPUSHED commits! 您有未推送的提交！
   Please run: git push
```

## 📝 工作流程 (Workflow)

1. 編輯檔案 (Edit files)
2. 看到提醒後，執行 `git add .` 和 `git commit -m "描述您的更改"`
3. 如果看到未推送提醒，執行 `git push`
4. 確認所有更改都已經推送到 GitHub！

## 💡 給老師的說明 (For Teachers)

這個模板使用 `.devcontainer` 配置，可以在 GitHub Codespaces 中自動設置學生的開發環境。提醒功能會在每次打開終端時運行，幫助學生養成定期提交和推送程式碼的好習慣。

This template uses `.devcontainer` configuration to automatically set up student development environments in GitHub Codespaces. The reminder feature runs every time a terminal is opened, helping students develop the habit of regularly committing and pushing their code.