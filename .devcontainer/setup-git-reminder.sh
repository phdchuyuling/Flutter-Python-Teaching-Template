#!/bin/bash
# Setup script that runs once when the container is created

# Create the git reminder script in user's bin directory
mkdir -p ~/bin

# Add git reminder to bashrc
if ! grep -q "check-git-status.sh" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Git Push Reminder - 自動提醒 Git Push
# Automatically check for uncommitted/unpushed changes
if [ -f "${CODESPACE_VSCODE_FOLDER}/.devcontainer/check-git-status.sh" ]; then
    source "${CODESPACE_VSCODE_FOLDER}/.devcontainer/check-git-status.sh"
fi

# Show reminder on every prompt
PROMPT_COMMAND='check_git_status_prompt'
EOF
fi

echo "✅ Git push reminder system installed!"
echo "📝 You will see reminders when you have uncommitted or unpushed changes."
