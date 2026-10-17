-- ============================================================================
-- QuickEN: 100% On-Device macOS English Communication Copilot
-- Powered by Ollama & Hammerspoon
--
-- Hotkeys:
--   [Ctrl + Option + E] : In-Place Translation (Select text -> Instant English)
--   [Ctrl + Option + W] : Smart Floating Window (Translate, Polish & Surgical Refine)
-- ============================================================================

local OLLAMA_HOST = "http://127.0.0.1:11434"
local DEFAULT_MODEL = "qwen3.5:2b"
local KEEP_ALIVE_TIME = "3m"
local FRAME_SETTINGS_KEY = "quick_en_copilot_frame_v2"

local activeModel = DEFAULT_MODEL
local availableModels = { DEFAULT_MODEL }

-- Silently wake up local Ollama service if not running
local function startOllamaProcess()
    hs.task.new("/usr/bin/open", nil, {"-g", "-a", "Ollama"}):start()
    hs.timer.doAfter(0.3, function()
        hs.task.new("/bin/zsh", nil, {"-c", "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; pgrep -x ollama >/dev/null || (nohup ollama serve >/dev/null 2>&1 &)"}):start()
    end)
end

-- Detect installed Ollama models
local function detectModels(autoWake, callback)
    hs.http.asyncGet(OLLAMA_HOST .. "/api/tags", nil, function(status, body)
        if status == 200 and body then
            local ok, tags = pcall(hs.json.decode, body)
            if ok and tags and tags.models and #tags.models > 0 then
                availableModels = {}
                local foundActive = false
                for _, m in ipairs(tags.models) do
                    table.insert(availableModels, m.name)
                    if m.name == activeModel then foundActive = true end
                end
                if not foundActive then
                    for _, name in ipairs(availableModels) do
                        if name:find("qwen") or name:find("gemma") then
                            activeModel = name; foundActive = true; break
                        end
                    end
                    if not foundActive then activeModel = availableModels[1] end
                end
            end
            if callback then callback(true, activeModel, availableModels) end
        else
            if autoWake then startOllamaProcess() end
            if callback then callback(false, activeModel, availableModels) end
        end
    end)
end

-- Ollama Chat API wrapper with auto-wake & retry
local function requestOllamaChat(payloadTable, onSuccess, onProgress, onError, retryCount)
    retryCount = retryCount or 0
    local payload = hs.json.encode(payloadTable)

    hs.http.asyncPost(OLLAMA_HOST .. "/api/chat", payload, {["Content-Type"] = "application/json"}, function(code, resBody)
        if code == 200 and resBody then
            onSuccess(resBody)
            return
        end

        if code <= 0 and retryCount < 12 then
            if retryCount == 0 then startOllamaProcess() end
            if onProgress then
                onProgress(string.format("🔄 Waking up local Ollama service (%d/12)...", retryCount + 1))
            end
            hs.timer.doAfter(0.6, function()
                requestOllamaChat(payloadTable, onSuccess, onProgress, onError, retryCount + 1)
            end)
        else
            if onError then
                onError("Ollama connection error (HTTP " .. tostring(code) .. ")")
            end
        end
    end)
end

-- Prompt 1: Chinese/Mixed -> English & Rough English Grammar Polishing
local TO_EN_PROMPT = [[You are a professional bilingual translator and English writing assistant.
Rules:
1. If the input is Chinese or mixed Chinese-English: Translate every sentence into natural, idiomatic English FAITHFULLY.
2. If the input is rough English: Fix grammar, tense, and phrasing while keeping the exact meaning.
3. NEVER summarize or omit any details, numbers, technical terms, proper nouns, or parenthetical notes.
4. Strictly preserve original line breaks, paragraphs, and bullet points.
5. Output ONLY the final English text itself. Do NOT add any prefixes, labels, quotes, or explanations.]]

-- Prompt 2: Surgical In-Box Refinement (Keep existing English intact, translate newly inserted Chinese words)
local REFINE_EN_PROMPT = [[You are a surgical English editor and translator.
The user took an existing English text and edited parts of it by typing Chinese words/phrases (or rough English) directly inside the text.
Rules:
1. Keep all existing good English sentences and words UNCHANGED as much as possible.
2. Translate ONLY the newly added Chinese parts into natural, idiomatic English that blends seamlessly into the surrounding sentence structure and tense.
3. NEVER summarize or omit any details, numbers, proper nouns, or paragraphs.
4. Strictly preserve original line breaks and paragraphs.
5. Output ONLY the final complete English text. No prefixes, no quotes, no explanations.]]

-- Prompt 3: English -> Chinese Translation
local TO_CN_PROMPT = [[You are a professional bilingual translator.
Rules:
1. Translate the user's English input into natural, accurate, and fluent Chinese FAITHFULLY.
2. NEVER summarize or omit any details, numbers, or nuances.
3. Strictly preserve original line breaks, paragraphs, and bullet points.
4. Keep standard technical terms, product names, and acronyms intact where appropriate.
5. Output ONLY the final Chinese translation. No prefixes, no quotes, no explanations.]]

-- ============================================================================
-- Mode A: [Ctrl + Option + E] In-Place Translation
-- ============================================================================
hs.hotkey.bind({"ctrl", "alt"}, "E", function()
    local oldClip = hs.pasteboard.getContents()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({"cmd"}, "c")

    hs.timer.doAfter(0.15, function()
        local text = hs.pasteboard.getContents()
        if not text or text:match("^%s*$") then
            if oldClip then hs.pasteboard.setContents(oldClip) end
            hs.alert.show("⚠️ Please select text first", 1)
            return
        end

        hs.alert.closeAll()
        local loadingAlert = hs.alert.show("⚡ Translating...", 15)

        local payloadTable = {
            model = activeModel,
            messages = {
                { role = "system", content = TO_EN_PROMPT },
                { role = "user", content = text }
            },
            stream = false,
            think = false,
            keep_alive = KEEP_ALIVE_TIME,
            options = { temperature = 0.2, num_predict = 512 }
        }

        requestOllamaChat(payloadTable, function(resBody)
            hs.alert.closeSpecific(loadingAlert)
            local ok, data = pcall(hs.json.decode, resBody)
            if ok and data and data.message and data.message.content then
                local out = data.message.content:gsub("<think>.-</think>", ""):gsub("^.-</think>", ""):gsub("<think>.*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if out ~= "" then
                    hs.pasteboard.setContents(out)
                    hs.eventtap.keyStroke({"cmd"}, "v")
                end
            end
        end, function(progressMsg)
            hs.alert.closeSpecific(loadingAlert)
            loadingAlert = hs.alert.show(progressMsg, 10)
        end, function(errMsg)
            hs.alert.closeSpecific(loadingAlert)
            hs.alert.show("❌ " .. errMsg, 2)
        end)
    end)
end)

-- ============================================================================
-- Mode B: [Ctrl + Option + W] Smart Floating Window (900x520)
-- ============================================================================
local copilotPanel = nil

local function savePanelFrame()
    if copilotPanel then
        local f = copilotPanel:frame()
        if f and f.w > 300 and f.h > 200 then
            hs.settings.set(FRAME_SETTINGS_KEY, { x = f.x, y = f.y, w = f.w, h = f.h })
        end
    end
end

local HTML_UI = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif; }
  html, body {
    width: 100%; height: 100vh; background: #181825; color: #cdd6f4;
    padding: 14px 18px; user-select: none; overflow: hidden;
    display: flex; flex-direction: column;
  }
  .top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; font-size: 13px; color: #a6adc8; flex-shrink: 0; }
  .title-wrap { display: flex; align-items: center; gap: 10px; }
  select.model-select {
    background: #313244; color: #a6e3a1; border: 1px solid #45475a;
    padding: 3px 10px; border-radius: 6px; font-weight: 600; font-size: 12px;
    outline: none; cursor: pointer;
  }
  .btn-top {
    background: transparent; color: #9399b2; border: 1px solid #313244;
    border-radius: 6px; padding: 3px 9px; font-size: 11.5px; cursor: pointer;
  }
  .btn-top:hover { color: #f9e2af; border-color: #45475a; }
  textarea.input-box {
    width: 100%; flex: 1; min-height: 95px; background: #1e1e2e; color: #ffffff;
    border: 1px solid #45475a; border-radius: 8px; padding: 12px 14px;
    font-size: 15px; line-height: 1.55; resize: none; outline: none; overflow-y: auto;
  }
  textarea.input-box:focus { border-color: #89b4fa; box-shadow: 0 0 0 2px rgba(137,180,250,0.2); }
  .action-bar {
    display: flex; justify-content: space-between; align-items: center;
    margin-top: 10px; margin-bottom: 10px; flex-shrink: 0; gap: 12px;
  }
  .btn-group { display: flex; gap: 8px; align-items: center; }
  button.act-btn {
    border: none; border-radius: 6px; padding: 6px 13px;
    font-size: 12.5px; font-weight: 600; cursor: pointer; transition: all 0.15s;
    display: inline-flex; align-items: center; gap: 4px; white-space: nowrap;
  }
  .btn-translate { background: #89b4fa; color: #11111b; }
  .btn-translate:hover { background: #b4befe; }
  .btn-to-cn { background: #313244; color: #89dceb; border: 1px solid #45475a; }
  .btn-to-cn:hover { background: #45475a; color: #ffffff; }
  .btn-refine { background: #313244; color: #f9e2af; border: 1px solid #45475a; }
  .btn-refine:hover { background: #45475a; color: #ffffff; }
  .btn-copy { background: #313244; color: #a6e3a1; border: 1px solid #45475a; }
  .btn-copy:hover { background: #45475a; color: #ffffff; }
  .btn-clear { background: transparent; color: #9399b2; border: 1px solid #313244; font-weight: 400; }
  .btn-clear:hover { color: #cdd6f4; border-color: #45475a; }
  textarea.output-box {
    width: 100%; flex: 1.25; min-height: 115px;
    background: #11111b; color: #a6e3a1; border: 1px solid #313244; border-radius: 8px;
    padding: 12px 14px; font-family: "Menlo", "PingFang SC", monospace;
    font-size: 14.5px; line-height: 1.55; resize: none; outline: none; overflow-y: auto;
  }
  textarea.output-box:focus { border-color: #f9e2af; box-shadow: 0 0 0 2px rgba(249,226,175,0.18); }
  textarea.output-box::placeholder { color: #585b70; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif; }
</style>
</head>
<body>
  <div class="top-bar">
    <div class="title-wrap">
      <span>⚡ <b>EN</b></span>
      <select id="model-select" class="model-select" onchange="changeModel(this.value)">
        <option>Detecting models...</option>
      </select>
      <button class="btn-top" onclick="unloadMemory()" title="Immediately unload model from RAM">🧹 Free RAM</button>
    </div>
    <span id="status">Ready (Auto-free RAM after 3m idle)</span>
  </div>

  <textarea id="cn-input" class="input-box" placeholder="输入中文、中英混杂(不会的词打中文) 或 英文草稿... (按 Enter 译为英文)"></textarea>

  <div class="action-bar">
    <div class="btn-group">
      <button class="act-btn btn-translate" onclick="triggerTranslate('en')">⚡ 译为英文 (Enter)</button>
      <button class="act-btn btn-to-cn" onclick="triggerTranslate('cn')">📖 译为中文 (⌘J)</button>
      <button class="act-btn btn-refine" onclick="triggerRefineOutput()" title="在下方英文结果中直接输入中文修改，点此或在下框按 Enter 即可局部转成英文">✨ 下框微调转英 (下框Enter)</button>
      <button id="copy-btn" class="act-btn btn-copy" onclick="copyResult()">📋 复制 (⌘⇧C)</button>
      <button class="act-btn btn-clear" onclick="clearAll()">清空</button>
    </div>
    <span style="font-size:11.5px; color:#6c7086; white-space:nowrap;">Shift+Enter 换行 | Esc 隐藏</span>
  </div>

  <textarea id="en-out" class="output-box" placeholder="翻译结果自动写入剪贴板。若想微调英文，可直接在英文里输入中文词句，然后按 Enter 即可将中文局部转成地道英文..."></textarea>

<script>
  const input = document.getElementById('cn-input');
  const enOut = document.getElementById('en-out');
  const statusEl = document.getElementById('status');
  const modelSelect = document.getElementById('model-select');
  const copyBtn = document.getElementById('copy-btn');

  let isComposingInput = false;
  let isComposingOut = false;
  let isTranslating = false;

  function postAction(action, data) {
    window.webkit.messageHandlers.copilot.postMessage({ action, data });
  }

  input.addEventListener('compositionstart', () => { isComposingInput = true; });
  input.addEventListener('compositionend', () => { isComposingInput = false; });

  enOut.addEventListener('compositionstart', () => { isComposingOut = true; });
  enOut.addEventListener('compositionend', () => { isComposingOut = false; });

  function changeModel(val) {
    postAction("setModel", val);
    input.focus();
  }

  function triggerTranslate(mode) {
    mode = mode || 'en';
    const text = input.value.trim();
    if (!text || isTranslating) return;
    isTranslating = true;
    const actionLabel = (mode === 'cn') ? "译为中文" : "译为英文";
    statusEl.innerText = "⏳ 正在调用 " + modelSelect.value + " (" + actionLabel + ")...";
    statusEl.style.color = "#f9e2af";
    enOut.style.color = "#6c7086";
    enOut.value = "正在推理...";
    postAction("translate", { text: text, mode: mode });
  }

  function triggerRefineOutput() {
    const text = enOut.value.trim();
    if (!text || text === "正在推理..." || isTranslating) return;
    isTranslating = true;
    statusEl.innerText = "✨ 正在将下框中的中文微调融合为地道英文...";
    statusEl.style.color = "#f9e2af";
    enOut.style.color = "#6c7086";
    postAction("translate", { text: text, mode: "refine" });
  }

  enOut.addEventListener('input', () => {
    statusEl.innerText = "✏️ 若输入了中文微调，直接按 Enter 即可局部转为英文；或点「📋 复制」";
    statusEl.style.color = "#f9e2af";
  });

  function copyResult() {
    const val = enOut.value.trim();
    if (!val || val === "正在推理...") return;
    postAction("copy", val);
    copyBtn.innerText = "✅ 已复制！";
    statusEl.innerText = "✅ 已复制最新内容到剪贴板，去任意位置 Cmd+V 粘贴";
    statusEl.style.color = "#a6e3a1";
    setTimeout(() => {
      copyBtn.innerText = "📋 复制 (⌘⇧C)";
    }, 1500);
  }

  function clearAll() {
    input.value = "";
    enOut.value = "";
    enOut.style.color = "#a6e3a1";
    statusEl.innerText = "已清空";
    statusEl.style.color = "#a6adc8";
    input.focus();
  }

  function unloadMemory() {
    statusEl.innerText = "🧹 正在从内存卸载模型...";
    statusEl.style.color = "#f9e2af";
    postAction("unload", "");
  }

  input.addEventListener('keydown', (e) => {
    if (isComposingInput || e.keyCode === 229) return;
    if (e.key === 'Enter' && !e.shiftKey && !e.metaKey) {
      e.preventDefault();
      triggerTranslate('en');
    }
  });

  enOut.addEventListener('keydown', (e) => {
    if (isComposingOut || e.keyCode === 229) return;
    if (e.key === 'Enter' && !e.shiftKey && !e.metaKey) {
      e.preventDefault();
      triggerRefineOutput();
    }
  });

  window.addEventListener('keydown', (e) => {
    if (isComposingInput || isComposingOut || e.keyCode === 229) return;
    if (e.key === 'Enter' && e.metaKey) {
      e.preventDefault();
      if (document.activeElement === enOut) {
        triggerRefineOutput();
      } else {
        triggerTranslate('en');
      }
    } else if (e.metaKey && (e.key === 'j' || e.key === 'J')) {
      e.preventDefault();
      triggerTranslate('cn');
    } else if (e.metaKey && e.shiftKey && (e.key === 'c' || e.key === 'C')) {
      e.preventDefault();
      copyResult();
    } else if (e.key === 'Escape') {
      e.preventDefault();
      postAction("close", "");
    }
  });

  window.syncModels = function(online, active, list) {
    modelSelect.innerHTML = "";
    list.forEach(m => {
      const opt = document.createElement('option');
      opt.value = m;
      opt.innerText = "🧠 " + m;
      if (m === active) opt.selected = true;
      modelSelect.appendChild(opt);
    });
    if (!online) {
      statusEl.innerText = "🟡 正在后台自动唤醒 Ollama 服务...";
      statusEl.style.color = "#f9e2af";
    } else if (!isTranslating) {
      statusEl.innerText = "🟢 Ollama 已就绪 (闲置3分钟自动释放内存)";
      statusEl.style.color = "#a6adc8";
    }
    input.focus();
    input.select();
  };

  window.updateProgress = function(msg) {
    statusEl.innerText = msg;
    statusEl.style.color = "#f9e2af";
    enOut.value = msg;
  };

  window.updateResult = function(payload, elapsedSec) {
    isTranslating = false;
    const text = (typeof payload === "object" && payload !== null) ? payload.en : payload;
    const mode = (typeof payload === "object" && payload !== null) ? payload.mode : "en";
    enOut.style.color = (mode === "cn") ? "#89dceb" : "#a6e3a1";
    enOut.value = text;
    if (mode === "refine") {
      statusEl.innerText = "✨ 下框微调已完成并自动复制 (" + elapsedSec + "s)！可继续输入中文按 Enter 微调";
    } else {
      statusEl.innerText = "✅ 已生成并自动复制 (" + elapsedSec + "s) · 可在下框直接打中文按 Enter 微调";
    }
    statusEl.style.color = "#a6e3a1";
  };

  window.updateUnloadDone = function(modelName) {
    statusEl.innerText = "🧹 已将 " + modelName + " 从内存彻底释放！下次翻译自动加载";
    statusEl.style.color = "#89dceb";
  };

  window.updateError = function(errMsg) {
    isTranslating = false;
    enOut.style.color = "#f38ba8";
    enOut.value = "❌ " + errMsg;
    statusEl.innerText = "调用失败，请重试";
    statusEl.style.color = "#f38ba8";
  };

  window.addEventListener('DOMContentLoaded', () => {
    postAction("ready", "");
  });
</script>
</body>
</html>
]]

local function refreshPanelStatus()
    detectModels(true, function(online, active, list)
        if copilotPanel then
            copilotPanel:evaluateJavaScript(string.format("window.syncModels(%s, %q, %s)", tostring(online), active, hs.json.encode(list)))
        end
        if not online then
            hs.timer.doAfter(1.2, function()
                detectModels(false, function(online2, active2, list2)
                    if copilotPanel then
                        copilotPanel:evaluateJavaScript(string.format("window.syncModels(%s, %q, %s)", tostring(online2), active2, hs.json.encode(list2)))
                    end
                end)
            end)
        end
    end)
end

local function createCopilotPanel()
    local screenFrame = hs.screen.mainScreen():frame()
    local saved = hs.settings.get(FRAME_SETTINGS_KEY)
    local rect
    if saved and saved.w and saved.h and saved.w >= 860 then
        rect = hs.geometry.rect(saved.x, saved.y, saved.w, saved.h)
    else
        local w, h = 900, 520
        rect = hs.geometry.rect(
            screenFrame.x + (screenFrame.w - w) / 2,
            screenFrame.y + (screenFrame.h - h) * 0.22,
            w, h
        )
    end

    local ucc = hs.webview.usercontent.new("copilot")
    ucc:setCallback(function(msg)
        local body = msg.body
        if not body then return end

        if body.action == "ready" then
            refreshPanelStatus()

        elseif body.action == "setModel" then
            activeModel = body.data

        elseif body.action == "close" then
            savePanelFrame()
            copilotPanel:hide()

        elseif body.action == "copy" then
            hs.pasteboard.setContents(body.data)

        elseif body.action == "unload" then
            local unloadPayload = hs.json.encode({
                model = activeModel,
                messages = {},
                keep_alive = 0
            })
            hs.http.asyncPost(OLLAMA_HOST .. "/api/chat", unloadPayload, {["Content-Type"] = "application/json"}, function()
                copilotPanel:evaluateJavaScript(string.format("window.updateUnloadDone(%q)", activeModel))
            end)

        elseif body.action == "translate" then
            savePanelFrame()
            local rawInput = type(body.data) == "table" and body.data.text or tostring(body.data)
            local mode = type(body.data) == "table" and body.data.mode or "en"
            local sysPrompt = TO_EN_PROMPT
            if mode == "cn" then
                sysPrompt = TO_CN_PROMPT
            elseif mode == "refine" then
                sysPrompt = REFINE_EN_PROMPT
            end
            local startTime = hs.timer.secondsSinceEpoch()

            local payloadTable = {
                model = activeModel,
                messages = {
                    { role = "system", content = sysPrompt },
                    { role = "user", content = rawInput }
                },
                stream = false,
                think = false,
                keep_alive = KEEP_ALIVE_TIME,
                options = { temperature = 0.2, num_predict = 512 }
            }

            requestOllamaChat(payloadTable, function(resBody)
                local ok, data = pcall(hs.json.decode, resBody)
                if not ok or not data or not data.message then
                    copilotPanel:evaluateJavaScript("window.updateError('返回数据解析失败')")
                    return
                end

                local out = data.message.content:gsub("<think>.-</think>", ""):gsub("^.-</think>", ""):gsub("<think>.*", ""):gsub("^%s+", ""):gsub("%s+$", "")

                if out ~= "" then
                    hs.pasteboard.setContents(out)
                end

                local elapsed = string.format("%.2f", hs.timer.secondsSinceEpoch() - startTime)
                copilotPanel:evaluateJavaScript("window.updateResult(" .. hs.json.encode({en = out, mode = mode}) .. ", " .. string.format("%q", elapsed) .. ")")
            end, function(progressMsg)
                copilotPanel:evaluateJavaScript(string.format("window.updateProgress(%q)", progressMsg))
            end, function(errMsg)
                copilotPanel:evaluateJavaScript(string.format("window.updateError(%q)", errMsg))
            end)
        end
    end)

    copilotPanel = hs.webview.new(rect, { developerExtrasEnabled = false }, ucc)
    copilotPanel:windowTitle("⚡ Quick EN (Ctrl+Opt+W)")
    copilotPanel:windowStyle({"titled", "closable", "resizable", "utility", "nonactivating"})
    copilotPanel:level(hs.drawing.windowLevels.floating)
    copilotPanel:allowTextEntry(true)
    copilotPanel:windowCallback(function(act)
        if act == "closing" or act == "frameChange" then
            savePanelFrame()
        end
    end)
    copilotPanel:html(HTML_UI)
end

hs.hotkey.bind({"ctrl", "alt"}, "W", function()
    if not copilotPanel then createCopilotPanel() end
    if copilotPanel:isVisible() then
        savePanelFrame()
        copilotPanel:hide()
    else
        copilotPanel:show()
        copilotPanel:hswindow():focus()
        refreshPanelStatus()
    end
end)

hs.alert.show("🟢 QuickEN Ready: Ctrl+Opt+E (In-Place) | Ctrl+Opt+W (Window)", 1.8)
