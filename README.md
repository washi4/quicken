# ⚡ QuickEN — 100% On-Device macOS English Communication Copilot

[![Platform](https://img.shields.io/badge/Platform-macOS%20(Apple%20Silicon)-blue?logo=apple)](#)
[![Engine](https://img.shields.io/badge/Engine-Ollama%20%2B%20Hammerspoon-success)](#)
[![TTS](https://img.shields.io/badge/TTS-Phonon%2040M%20(On--Device)-purple)](#)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local%20Offline-brightgreen)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Output-first, zero-cloud, instant English writing, refinement & TTS copilot for daily Teams / Slack / Email communication on macOS.**
>
> **专为跨国团队日常 IM 沟通打造的 Mac 本地极速英语双模助手：支持原地秒换英文（`⌃⌥E`）、宽屏智能微调悬浮窗（`⌃⌥W`）以及本地真人级英文朗读（`⌘L`）。100% 本地离线运行，零 API 成本，仅占约 2GB 内存。**

---

## 🎬 Demo (实机演示)

https://github.com/user-attachments/assets/0a4eec97-5365-4b11-ac5e-4328f2109a6d

https://github.com/user-attachments/assets/3f921327-bed5-4e2a-a8d2-79e42b97150b

---

## 🎯 Why QuickEN? (为什么做这个工具？)

Most translation tools (like Bob, Pot, or browser extensions) are **reading-oriented (English $\rightarrow$ Chinese)** and require switching windows or paying for cloud APIs.

When communicating with global teams in **Microsoft Teams, Slack, or Web Outlook**, non-native speakers face four daily friction points:
1. **Typing in Chinese (or via voice dictation)** and wanting instant, idiomatic English without leaving the chat box.
2. **Getting stuck on a specific word while typing English** (e.g., `"The pod failed to start, 好像是证书过期了, can you check?"`).
3. **Wanting to tweak a translated English sentence by typing Chinese directly inside the English result** without rewriting the rest of the sentence.
4. **Wanting to hear how a sentence sounds in natural English** before speaking up in a global meeting.

**QuickEN** solves all of these in **0.2 seconds** using a 2GB local LLM (`qwen3.5:2b`) + a 140MB local TTS model (`phonon:40m-en`) via **Ollama** and **Hammerspoon**.

---

## ✨ Key Features (核心特性)

- ⚡ **Mode A — In-Place Instant Replacement (`Ctrl + Option + E`)**
  Select any Chinese, mixed Chinese-English, or rough English text in Teams/Slack/Browser and press `⌃⌥E`. It replaces your selection in-place with natural, idiomatic English in ~0.2s.
- 🪟 **Mode B — Smart Floating Copilot Window (`Ctrl + Option + W`)**
  - **3-in-1 Idiomatic Translation (`Enter`)**: Pure Chinese translation, mixed English+Chinese completion, and rough English grammar polishing (avoids word-for-word Chinglish while keeping 100% of details and line breaks).
  - **Surgical In-Box Refinement (下框中文微调转英)**: Edit the generated English in the bottom box by typing Chinese words directly where you want changes, then press `Enter` in the bottom box—QuickEN translates *only* your Chinese edits while keeping the rest of your English intact!
  - **On-Device Natural TTS Read-Aloud (`🔊 朗读 / ⌘L`)**: Powered by Ollama's native `phonon:40m-en` (140MB MLX speech model). Listen to natural English pronunciation with one click, and press `⌘L` again (or `Esc`) to stop immediately.
  - **English to Chinese (`⌘J`)**: Quickly translate incoming English messages into accurate Chinese.
- 🧠 **Smart Memory Management (16GB Mac Friendly)**
  - Auto-wakes Ollama in the background if it isn't running (no more `Connection Refused` errors).
  - Automatically unloads models from RAM after **3 minutes of idle time**, plus a one-click **`🧹 释放内存`** button.
- 🔒 **Single Accessibility Permission & 100% On-Device Privacy**
  - Powered by Hammerspoon: grant Accessibility permission **once**, and it works across all desktop apps and web browsers forever.

---

## 🚀 Quick Start (3分钟快速安装)

### Step 1: Install Ollama & Pull Local Models (LLM + TTS)
```bash
# 1. Install Ollama (v0.40.11+ required for native Phonon TTS)
brew install --cask ollama

# 2. Pull the 2.0GB pure-text, non-thinking Q8 model and alias it to qwen3.5:2b
ollama pull sorc/qwen3.5-instruct-uncensored:2b
ollama cp sorc/qwen3.5-instruct-uncensored:2b qwen3.5:2b
ollama rm sorc/qwen3.5-instruct-uncensored:2b

# 3. Pull the 140MB Phonon 40M English TTS model for read-aloud (⌘L)
ollama pull phonon:40m-en

# 4. Allow both the 2GB LLM and 140MB TTS model to coexist in RAM
launchctl setenv OLLAMA_MAX_LOADED_MODELS 2

# (Optional) Alternative Google Gemma 4 edge model
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
git clone https://github.com/washi4/quicken.git
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
| <kbd>Cmd</kbd> + <kbd>L</kbd> | Floating Window | **Read Aloud / Stop**: Speak the English text via local `phonon:40m-en` TTS (press again to stop) |
| <kbd>Cmd</kbd> + <kbd>J</kbd> | Floating Window | Translate English input in top box into Chinese |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> | Floating Window | Copy current text from the bottom output box |
| <kbd>Shift</kbd> + <kbd>Enter</kbd> | Floating Window | Insert a newline |
| <kbd>Esc</kbd> | Floating Window | Stop audio, hide window & save window position/size |

---

## 🛠️ Customization (自定义配置)

Open `~/.hammerspoon/init.lua` to customize:
- `DEFAULT_MODEL`: Default is `"qwen3.5:2b"` (you can also switch text models live from the top dropdown in the floating window; `phonon` TTS models are automatically filtered out of the text dropdown).
- `DEFAULT_TTS_MODEL` & `voice`: Uses `"phonon:40m-en"`. In the `speak` handler, you can change `voice` to `"Easton"` (male), `"Zoey"` (female), `"Freya"`, or `"default"`.
- `KEEP_ALIVE_TIME`: Default is `"3m"` (automatically frees RAM after 3 minutes of inactivity).
- `TO_EN_PROMPT` / `REFINE_EN_PROMPT`: Customize translation rules or add your team's terminology glossary.

---

## 📄 License

Released under the [MIT License](LICENSE).