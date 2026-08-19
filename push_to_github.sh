#!/bin/bash
# ==============================================================================
# G28 STEPPER CONTROLLER — AUTOMATIC GITHUB REPOSITORY CREATOR & PUSHER
# ==============================================================================
set -e

export PATH="$HOME/.local/bin:$HOME/.local/usr/bin:$PATH"
export GIT_EXEC_PATH="$HOME/.local/usr/lib/git-core"

echo "========================================================"
echo "  🛸 G28 STEPPER CONTROLLER — GITHUB AUTOMATION SCRIPT  "
echo "========================================================"

# Check if authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "🔑 GitHub login required. Starting one-time web login..."
  gh auth login --hostname github.com -p https -w
fi

# Create GitHub repository (or push if origin already exists)
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "🚀 Creating public GitHub repository 'g28-stepper-controller' and pushing..."
  gh repo create g28-stepper-controller --public --source=. --remote=origin --push
else
  echo "🚀 Pushing latest commits to origin main..."
  git push -u origin main
fi

USER_LOGIN=$(gh api user -q .login 2>/dev/null || echo "<your-username>")

echo ""
echo "========================================================"
echo "  ✅ SUCCESS! Repository created and pushed!            "
echo "========================================================"
echo "📁 GitHub Repo:   https://github.com/$USER_LOGIN/g28-stepper-controller"
echo "🌐 Enable Pages:  https://github.com/$USER_LOGIN/g28-stepper-controller/settings/pages"
echo "🎯 Live Web App:  https://$USER_LOGIN.github.io/g28-stepper-controller/"
echo "========================================================"
