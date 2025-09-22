# Agent Sessions (macOS)

[![Build](https://github.com/jazzyalex/agent-sessions/actions/workflows/ci.yml/badge.svg)](https://github.com/jazzyalex/agent-sessions/actions/workflows/ci.yml)

> Fast, native macOS viewer/indexer for **Codex CLI** session logs.  
> Three-pane browser with full-text search, filters, and a clean SwiftUI UI.

<div align="center">
  <img src="assets/AgentSessions.png" alt="App Icon" width="96" height="96"/>
</div>

## ✨ What it is
- Reads **JSON Lines** logs produced by Codex CLI and builds a searchable timeline of sessions.
- **Three-pane UI**: sidebar (sessions), transcript, and details; debounced search and filters.
- **Privacy-friendly**: indexes **local files only**; no network required.

## 🧰 Requirements
- macOS 14 (Sonoma) or newer
- Xcode 15+ / Swift 5.9+

## 📦 Install

### Option A — Download
- Get the latest **.dmg** from [Releases](./releases) and drag to Applications.

### Option B — Build from source
```bash
git clone https://github.com/jazzyalex/agent-sessions.git
cd agent-sessions
open AgentSessions.xcodeproj
# Run the "AgentSessions" scheme
```