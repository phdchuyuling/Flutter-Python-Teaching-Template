# Git Push Reminder - Visual Examples

## Scenario 1: Uncommitted Changes

When you modify files but haven't committed them yet:

```bash
$ # After editing files...
$ # Terminal shows:

⚠️  WARNING: You have UNCOMMITTED changes! 您有未提交的更改！
   Please run: git add . && git commit -m 'your message'
```

**What to do:**
```bash
git add .
git commit -m "Description of your changes"
```

---

## Scenario 2: Unpushed Commits

When you have committed changes locally but haven't pushed to GitHub:

```bash
$ # After committing...
$ # Terminal shows:

⚠️  WARNING: You have UNPUSHED commits! 您有未推送的提交！
   Please run: git push
```

**What to do:**
```bash
git push
```

---

## Scenario 3: All Clear

When everything is committed and pushed:

```bash
$ # Terminal shows no warnings - you're all good! ✅
```

---

## How It Works

1. **On Terminal Open**: The reminder checks your git status automatically
2. **On Every Command**: After each command, it checks again (via PROMPT_COMMAND)
3. **Visual Warnings**: Clear, bilingual warnings help you remember to commit and push

## For Students (學生使用指南)

### 工作流程 (Workflow)
1. 📝 編輯檔案 (Edit files)
2. ⚠️ 看到提醒 (See warning)
3. ✅ 執行指令 (Run commands):
   - `git add .`
   - `git commit -m "你的更改說明"`
   - `git push`
4. 🎉 完成！(Done!)

### 常見問題 (FAQ)

**Q: 為什麼我一直看到提醒？**
A: 因為你還沒有完成 `git add`, `git commit`, 或 `git push`。

**Q: 我可以關閉這個功能嗎？**
A: 可以，但不建議。這是為了幫助你養成良好的版本控制習慣。

**Q: 提醒什麼時候會出現？**
A: 每次你打開新終端或執行命令時。
