#!/usr/bin/env bash
set -e

echo "⚡ Installing QuickEN for macOS..."

# 1. Check Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew not found. Please install Homebrew first: https://brew.sh"
  exit 1
fi

# 2. Check / Install Ollama
if ! command -v ollama >/dev/null 2>&1 && [ ! -d "/Applications/Ollama.app" ]; then
  echo "📦 Installing Ollama..."
  brew install --cask ollama
fi

# 3. Check / Install Hammerspoon
if [ ! -d "/Applications/Hammerspoon.app" ]; then
  echo "🔨 Installing Hammerspoon..."
  brew install --cask hammerspoon
fi

# 4. Pull model and create clean alias
echo "🧠 Pulling 2GB fast model (sorc/qwen3.5-instruct-uncensored:2b) and aliasing to qwen3.5:2b..."
ollama pull sorc/qwen3.5-instruct-uncensored:2b
ollama cp sorc/qwen3.5-instruct-uncensored:2b qwen3.5:2b
ollama rm sorc/qwen3.5-instruct-uncensored:2b || true
ollama pull phonon:40m-en

# 5. Copy init.lua
mkdir -p ~/.hammerspoon
if [ -f ~/.hammerspoon/init.lua ]; then
  cp ~/.hammerspoon/init.lua ~/.hammerspoon/init.lua.bak.$(date +%s)
  echo "📂 Backed up existing ~/.hammerspoon/init.lua"
fi
cp init.lua ~/.hammerspoon/init.lua

echo "✅ QuickEN installed successfully!"
echo "👉 Next step: Open Hammerspoon.app, enable it in System Settings -> Privacy & Security -> Accessibility, and click 'Reload Config'."
