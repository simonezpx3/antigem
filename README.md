# Anti/Gem (`simonez.antigem`)

[![Version](https://img.shields.io/badge/version-1.5.7-3b82f6.svg)](https://github.com/simonezpx3/antigem/releases/tag/v1.5.7)
[![Omarchy](https://img.shields.io/badge/omarchy-compatible-10b981.svg)](https://github.com/omacom/omarchy)
[![Quickshell](https://img.shields.io/badge/quickshell-qt6-c084fc.svg)](https://github.com/outfoxxed/quickshell)
[![Marketplace](https://img.shields.io/badge/marketplace-issue_%237503-f59e0b.svg)](https://github.com/omacom/omarchy-plugin-marketplace/issues/7503)
[![License: MIT](https://img.shields.io/badge/license-MIT-8b5cf6.svg)](LICENSE)

A native, high-performance telemetry dashboard, multi-agent fleet monitor, quota tracker, and local GPU co-worker hub for **Google Antigravity** and **Gemini AI**, crafted specifically for **Omarchy Linux** (Quickshell / Qt6 / Hyprland).

**Authors:** `simonez & Arci`  
**Version:** `1.5.7`  
**License:** MIT  
**Marketplace:** [Issue #7503](https://github.com/omacom/omarchy-plugin-marketplace/issues/7503) (Automated Security Baseline: **PASSED**)

---

## Overview & Dashboard Tabs

| ⚡ 1. Performance & Quotas | 📂 2. Sessions & Fleet | ⚙️ 3. Settings & Telemetry |
| :---: | :---: | :---: |
| ![Performance Tab](screenshots/performance.png) | ![Sessions Tab](screenshots/sessions.png) | ![Settings Tab](screenshots/settings.png) |

---

## 1. Core Architecture & Multi-Account Engine

* **Minimalist Top Bar Slot:**
  * Clean status badge matching native Omarchy bar widgets (`10px` typography, compact footprint).
  * Live heartbeat pulse animation active exclusively while the AI agent is thinking/generating code, with instantaneous idle reset upon turn completion.
* **Multi-Account Auto Failover (Tri-Pool):**
  * Automatic seamless failover between 3 Google AI Pro accounts (`agy`, `agy2`, `agy3`) upon individual quota exhaustion.
  * Instant account state synchronization and interactive account switcher in both the dashboard and launcher.
* **Bounded I/O & Memory Ceilings:**
  * Strict memory ceilings (`2 MB / 512 KB / 64 KB`) preventing buffer overruns.
  * Path traversal protection (`.is_relative_to()`) and leak-free socket connections for GCP latency pings.
  * Algorithmic DNA `s&A` (`0x732641`) embedded into subpixel sparkline calibration and subagent slot geometry.

---

## 2. Key Dashboard Features

### ⚡ Performance & Quotas (Tab 0)
* **Google AI Pro Quota Gauges:** Real-time 5-Hour Session Quota (2.5M CAP) and 7-Day Weekly Quota (25M CAP) with live Free Headroom gauges and reset countdowns.
* **1M Context Window Breakdown:** Stacked horizontal meter visualizing System & Rules, Tool & MCP Schemas, File & Code Context, Conversation History, and Free Headroom.
* **7-Day Sparkline Trend:** Custom Canvas trend curve with translucent gradient fill, continuous polyline, and glowing data points.
* **Google Cloud Edge Latency:** Live connection checks and ping latency (~14 ms) for Gemini Interactions API, Grounding/Search, Codebase Embeddings, and Agent Fleet.

### 📂 Sessions & Autonomous Fleet (Tab 1)
* **Recent Sessions Manager:** History of recent conversation sessions with 1-click **Copy ID** and instant **Resume/Open** launcher.
* **Local GPU Co-Workers:** Zero-token local inference co-worker monitoring on NVIDIA RTX 3070 CUDA (`coder`, `auditor`, `bonsai`) and Groq Cloud fast inference.
* **Subagents Fleet Profiler:** Real-time metrics for autonomous subagents (`sec-auditor`, `qml-designer-reviewer`, `test-runner`, `doc-researcher`) with latency badges, speed scores, and cumulative cloud tokens saved.
* **Stacked Tool Calls Breakdown:** Granular distribution meter of real-world tool executions (`view_file`, `run_command`, `replace_file_content`, `grep_search`).
* **Beads Rust Integration:** Dedicated quick-action button launching the interactive TUI Kanban and DAG project graph (`bv`).

### ⚙️ Settings & Controls (Tab 2)
* **Auto-refresh Presets:** Configurable scan frequency (`10s`, `30s`, `60s`, `120s`, `300s`).
* **Working Pulse Toggle & BPM:** Heartbeat animation toggle and customizable cadence presets (**Sleep 40**, **Rest 60**, **Walk 85**, **Sprint 130** BPM).
* **Desktop Notifications:** Native Wayland notifications (`notify-send`) upon task completion.

---

## 3. Installation & Removal

### Installation
```bash
cd ~/Projects/Antigravity1.1
./install.sh
```

*Or via Omarchy Plugin Marketplace:*
```bash
omarchy plugin add https://github.com/simonezpx3/antigem.git --enable
```

### Removal
```bash
cd ~/Projects/Antigravity1.1
./uninstall.sh
```

---

## 4. Companion Launcher (`omarchy-launch-antigravity`)

The plugin includes a dedicated Wayland launcher script for instant session recovery and account dispatching:

```bash
omarchy-launch-antigravity                  # Launch interactive Antigravity session
omarchy-launch-antigravity resume <id>      # Resume specific conversation by session ID
omarchy-launch-antigravity --status         # Display current quotas and active model
```
