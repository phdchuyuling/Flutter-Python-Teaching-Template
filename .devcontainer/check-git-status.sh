#!/bin/bash
# Script to check git status and show reminders

check_git_status_prompt() {
    # Only run in git repositories
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo ""
        echo "⚠️  WARNING: You have UNCOMMITTED changes! 您有未提交的更改！"
        echo "   Please run: git add . && git commit -m 'your message'"
        echo ""
    fi

    # Check for unpushed commits
    LOCAL=$(git rev-parse @ 2>/dev/null)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$LOCAL" != "$REMOTE" ]; then
        # Check if local is ahead
        if git rev-list --left-only --count @{u}... 2>/dev/null | grep -q "^0$"; then
            echo ""
            echo "⚠️  WARNING: You have UNPUSHED commits! 您有未推送的提交！"
            echo "   Please run: git push"
            echo ""
        fi
    fi
}

# Run once when script is sourced (terminal opens)
check_git_status_prompt
