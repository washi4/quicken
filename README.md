# ⚡ QuickEN — 100% On-Device macOS English Communication Copilot

[![Platform](https://img.shields.io/badge/Platform-macOS%20(Apple%20Silicon)-blue?logo=apple)](#)
[![Engine](https://img.shields.io/badge/Engine-Ollama%20%2B%20Hammerspoon-success)](#)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local%20Offline-brightgreen)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Output-first, zero-cloud, instant English writing & translation copilot for daily Teams / Slack / Email communication on macOS.**
>
> **专为跨国团队日常 IM 沟通打造的 Mac 本地极速英语双模助手：支持原地秒换英文（`⌃⌥E`）与宽屏智能微调悬浮窗（`⌃⌥W`）。100% 本地离线运行，零 API 成本，仅占 2GB 内存。**

---

## 🎯 Why QuickEN? (为什么做这个工具？)

Most translation tools (like Bob, Pot, or browser extensions) are **reading-oriented (English $\rightarrow$ Chinese)** and require switching windows or paying for cloud APIs.

When communicating with global teams in **Microsoft Teams, Slack, or Web Outlook**, non-native speakers face three daily friction points:
1. **Typing in Chinese (or via voice dictation)** and wanting instant, natural English without leaving the chat box.
2. **Getting stuck on a specific word while typing English** (e.g., `"The pod failed to start, 好像是证书过期了, can you check?"`).
3. **Wanting to tweak a translated English sentence by typing Chinese directly inside the English result** without re-rewriting the rest of the sentence.

**QuickEN** solves all three in **0.2 seconds** using a 2GB local LLM (`qwen3.5:2b` or `gemma4:e2b`) via **Ollama** and **Hammerspoon**.

---

## ✨ Key Features (核心特性)

- ⚡ **Mode A — In-Place Instant Replacement (`Ctrl + Option + E`)**
  Select any Chinese, mixed Chinese-English, or rough English text in Teams/Slack/Browser and press `⌃⌥E`. It replaces your selection in-place with natural English in ~0.2s.
- 🪟 **Mode B — Smart Floating Copilot Window (`Ctrl + Option + W`)**
  - **3-in-1 Input (`Enter`)**: Pure Chinese translation, mixed English+Chinese completion, and rough English grammar polishing.
  - **Surgical In-Box Refinement (下框中文微调转英)**: Edit the generated English in the bottom box by typing Chinese words directly where you want changes, then press `Enter` in the bottom box—QuickEN translates *only* your Chinese edits while keeping the rest of your English intact!
  - **English to Chinese (`⌘J`)**: Quickly translate incoming English messages into accurate Chinese.
- 🧠 **Smart Memory Management (16GB Mac Friendly)**
  - Auto-wakes Ollama in the background if it isn't running (no more `Connection Refused` errors).
  - Automatically unloads the model from RAM after **3 minutes of idle time**, plus a one-click **`🧹 Free RAM`** button.
- 🔒 **Single Accessibility Permission & 100% On-Device Privacy**
  - Powered by Hammerspoon: grant Accessibility permission **once**, and it works across all desktop apps and web browsers forever.

---

## 🚀 Quick Start (3分钟快速安装)

### Step 1: Install Ollama & Pull the 2GB Fast Model
```bash
# 1. Install Ollama
brew install --cask ollama

# 2. Pull the 2.0GB pure-text, non-thinking Q8 model and alias it to qwen3.5:2b
ollama pull sorc/qwen3.5-instruct-uncensored:2b
ollama cp sorc/qwen3.5-instruct-uncensored:2b qwen3.5:2b
ollama rm sorc/qwen3.5-instruct-uncensored:2b

# (Optional) Google Gemma 4 edge model
ollama pull gemma4:e2b
```

### Step 2: Install Hammerspoon
```bash
brew install --cask hammerspoon
```
1. Open **Hammerspoon.app**.
2. Go to **System Settings $\rightarrow$ Privacy & Security $\rightarrow$ Accessibility** and enable **Hammerspoon**.
3. Click the Hammerspoon menu bar icon $\rightarrow$ `Preferences` and check **Launch Hammerspoon at login**.

### Step 3: Install QuickEN Script
```bash
git clone https://github.com/YOUR_USERNAME/quicken.git
mkdir -p ~/.hammerspoon
cp quicken/init.lua ~/.hammerspoon/init.lua
```
Click the Hammerspoon menu bar icon $\rightarrow$ **Reload Config** (or run `hs.reload()` in the Hammerspoon Console).

---

## ⌨️ Usage & Shortcuts (日常使用连招)

| Shortcut | Context | Action |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Option</kbd> + <kbd>E</kbd> | Any App (Teams / Slack / Browser) | **In-Place Translate**: Replaces selected text with natural English & copies to clipboard |
| <kbd>Ctrl</kbd> + <kbd>Option</kbd> + <kbd>W</kbd> | Global | **Toggle Floating Window**: Show/hide the QuickEN window (remembers size & position) |
| <kbd>Enter</kbd> *(in Top Box)* | Floating Window | Translate / polish top input into English & auto-copy to clipboard |
| <kbd>Enter</kbd> *(in Bottom Box)* | Floating Window | **Surgical Refine**: Translate Chinese edits typed inside the English output box |
| <kbd>Cmd</kbd> + <kbd>J</kbd> | Floating Window | Translate English input in top box into Chinese |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> | Floating Window | Copy current text from the bottom output box |
| <kbd>Shift</kbd> + <kbd>Enter</kbd> | Floating Window | Insert a newline |
| <kbd>Esc</kbd> | Floating Window | Hide window & save window position/size |

---

## 🛠️ Customization (自定义配置)

Open `~/.hammerspoon/init.lua` to customize:
- `DEFAULT_MODEL`: Default is `"qwen3.5:2b"` (you can also switch models live from the top dropdown in the floating window).
- `KEEP_ALIVE_TIME`: Default is `"3m"` (automatically frees RAM after 3 minutes of inactivity).
- `TO_EN_PROMPT` / `REFINE_EN_PROMPT`: Customize translation rules or add your team's terminology glossary.

---

## 📄 License

Released under the [MIT License](LICENSE).
