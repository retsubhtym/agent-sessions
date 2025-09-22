# Agent Sessions (macOS)

[![Build](https://github.com/jazzyalex/agent-sessions/actions/workflows/ci.yml/badge.svg)](https://github.com/jazzyalex/agent-sessions/actions/workflows/ci.yml)

> Fast, native macOS viewer/indexer for **Codex CLI** session logs.  
> Three-pane browser with full-text search, filters, and a clean SwiftUI UI.

<div align="center">
  <img src="assets/AgentSessions.png" alt="App Icon" width="128" height="128"/>
</div>

---

## ✨ What it is
Agent Sessions reads **JSON Lines** logs produced by [Codex CLI](https://github.com/your-codex-cli-link)  
and builds a searchable timeline of your AI coding/chat sessions.

- 🗂 **Sidebar**: sessions grouped by *Today*, *Yesterday*, date, or *Older*  
- 📝 **Transcript view**: full session content with role-based styling and optional timestamps  
- 🔍 **Search & filters**: full-text search, date ranges, model filter, message-type toggles  
- 🎨 **SwiftUI design**: fast, clean, and privacy-friendly (local only)

---

## 🧰 Requirements
- macOS 14 (Sonoma) or newer
- Xcode 15+ / Swift 5.9+
- Codex CLI logs in `$CODEX_HOME/sessions/YYYY/MM/DD/rollout-*.jsonl`  
  *(or `~/.codex/sessions/...`)*

---

## 📦 Install

### Option A — Download
1. Grab the latest build from [Releases](https://github.com/jazzyalex/agent-sessions/releases).  
2. Drag **Agent Sessions.app** to your Applications folder.  

### Option B — Build from source
```bash
git clone https://github.com/jazzyalex/agent-sessions.git
cd agent-sessions
open AgentSessions.xcodeproj