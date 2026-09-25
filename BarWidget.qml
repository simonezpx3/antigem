import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "simonez.antigem"

  // Live State & Quotas
  property bool ready: false
  property bool active: false
  property string activeStatus: "Idle"
  property string tierLabel: "Google AI Pro"
  property string currentModel: "Gemini 3.8 Flash"
  property string activeVersion: "CLI v1.1.26"
  property string serverVersion: "CLI v1.1.26"
  property string serverVersionFull: "CLI v1.1.26"
  property int sessionGeminiPct: 0
  property string sessionGeminiDetail: "Resets in ~5h"
  property int weeklyGeminiPct: 0
  property string weeklyGeminiDetail: "Resets in ~7d"
  property var autoFailoverInfo: null

  // Token Metrics & Headroom (Google AI Pro)
  property var tokensData: ({})
  property string weeklyTokensUsed: "~24.5M"
  property string weeklyTokensRemaining: "~500k"
  property int weeklyTokensRemainingPct: 2
  property string weeklyTokensDetail: "Resets in ~1d 15h"
  property string weeklyTokensSeverity: "critical"
  property string sessionTokensUsed: "~75k"
  property string sessionTokensRemaining: "~2.42M"
  property string todayTokens: "~285k"
  property string allTimeTokens: "~48.6M"

  // Context Window & Breakdown
  property int contextPct: 0
  property string contextTokensStr: "0k / 1M"
  property var contextMap: ({})
  property int activeSubagents: 0
  property var productivityData: ({})
  property var quotasBreakdown: ({})
  property var activityBreakdown: ({})
  property bool notificationsEnabled: root.setting("notificationsEnabled", true) !== false
  
  function t(key, fallback) {
    return fallback || key
  }

  // Activity & Telemetry
  property int todayPrompts: 0
  property int totalPrompts: 0
  property var recentDays: []
  property var toolsList: []
  property var recentSessions: []
  property var featuredSessions: []
  property var gcpInfo: null
  property var localAiInfo: null
  property var subagentsFleet: []
  property var subagentProfiler: []
  property bool opened: false
  property bool popoutSwitchClosing: false
  property alias popupOpen: root.opened

  // Active status helper
  readonly property bool isWorking: activeStatus === "Working"
  readonly property bool isWaiting: activeStatus === "Waiting"

  readonly property int totalToolCalls: {
    var sum = 0
    if (toolsList && toolsList.length) {
      for (var i = 0; i < toolsList.length; i++) {
        sum += (toolsList[i] && toolsList[i].count ? Number(toolsList[i].count) : 0)
      }
    }
    return sum
  }

  readonly property int maxDayPrompts: {
    var maxVal = 1
    if (recentDays && recentDays.length) {
      for (var i = 0; i < recentDays.length; i++) {
        var p = (recentDays[i] && recentDays[i].prompts) ? Number(recentDays[i].prompts) : 0
        if (p > maxVal) maxVal = p
      }
    }
    return maxVal
  }

  // Exact System Monitor Color Scheme
  readonly property url appIconPath: Qt.resolvedUrl("assets/antigravity_logo.png")
  readonly property url appIconPanelPath: Qt.resolvedUrl("assets/antigravity_logo_panel.png")
  readonly property color foreground: (bar && bar.foreground) ? bar.foreground : Color.foreground
  readonly property color background: Color.background
  readonly property color urgent: (bar && bar.urgent) ? bar.urgent : Color.urgent
  readonly property color accent: (bar && bar.accent) ? bar.accent : Color.accent

  // Dynamic System Theme Adapter (Adapts 100% natively on every PC and active theme)
  property var themeColors: ({})

  FileView {
    id: themeColorsWatcher
    path: Color.currentThemePath + "/colors.toml"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var lines = String(text() || "").split("\n")
      var dict = {}
      for (var i = 0; i < lines.length; i++) {
        var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
        if (match) {
          dict[match[1]] = match[2]
        }
      }
      root.themeColors = dict
    }
  }

  function getThemeColor(key, fallback) {
    if (root.themeColors && root.themeColors[key]) return root.themeColors[key]
    return fallback
  }

  // System Monitor palette tokens (Live adaptive to any Omarchy / System theme)
  readonly property color cpuColor: getThemeColor("cyan", getThemeColor("accent", Color.accent))
  readonly property color uploadColor: getThemeColor("green", "#34d399")
  readonly property color memoryColor: getThemeColor("magenta", getThemeColor("blue", "#c084fc"))
  readonly property color downloadColor: getThemeColor("bright_cyan", getThemeColor("cyan", "#2dd4bf"))
  readonly property color loadColor: getThemeColor("yellow", "#fbbf24")
  readonly property color uptimeColor: getThemeColor("dark_foreground", getThemeColor("muted", Color.muted))
  readonly property color gpuColor: getThemeColor("magenta", "#f472b6")
  readonly property color temperatureColor: getThemeColor("orange", "#fb923c")
  readonly property color warningColor: getThemeColor("yellow", "#fbbf24")
  readonly property color criticalColor: getThemeColor("red", Color.urgent)

  readonly property var sliceColors: [
    cpuColor,
    downloadColor,
    memoryColor,
    uploadColor,
    loadColor,
    gpuColor,
    temperatureColor,
    uptimeColor
  ]
  readonly property var topToolsList: (toolsList && toolsList.length > 0) ? toolsList.slice(0, 8) : []

  function launchSession(session) {
    if (!session) return
    if (root.bar && typeof root.bar.run === "function") {
      var type = String(session.type || "cli").replace(/[^a-zA-Z0-9_\-]/g, "")
      var id = String(session.id || "").replace(/[^a-zA-Z0-9_\-]/g, "")
      var ws = String(session.workspace || "")
      var escapedWs = "'" + ws.replace(/'/g, "'\\''") + "'"
      root.bar.run("omarchy-launch-antigravity " + type + " " + id + " " + escapedWs)
    }
    root.close()
  }

  function resolveSegmentColor(item, fallback) {
    if (!item) return fallback || root.primaryAccent
    var name = String(item.name || item.id || "").toLowerCase()
    if (name.indexOf("headroom") !== -1 || name.indexOf("free") !== -1) return root.headroomColor
    if (name.indexOf("code") !== -1 || name.indexOf("today") !== -1 || name.indexOf("security") !== -1 || name.indexOf("sec-auditor") !== -1 || name.indexOf("chat") !== -1 || name.indexOf("history") !== -1) return root.uploadColor
    if (name.indexOf("term") !== -1 || name.indexOf("command") !== -1 || name.indexOf("cmd") !== -1 || name.indexOf("test") !== -1) return root.loadColor
    if (name.indexOf("search") !== -1 || name.indexOf("find") !== -1 || name.indexOf("navig") !== -1 || name.indexOf("tool") !== -1 || name.indexOf("mcp") !== -1 || name.indexOf("qml") !== -1 || name.indexOf("session") !== -1) return root.primaryAccent
    if (name.indexOf("arch") !== -1 || name.indexOf("plan") !== -1 || name.indexOf("syst") !== -1 || name.indexOf("rule") !== -1 || name.indexOf("doc") !== -1 || name.indexOf("prior") !== -1) return root.memoryColor
    if (name.indexOf("file") !== -1) return root.downloadColor
    return item.color || fallback || root.primaryAccent
  }

  readonly property color primaryAccent: cpuColor
  readonly property color cardFill: Qt.rgba(accent.r, accent.g, accent.b, 0.045)
  readonly property color cardHover: Qt.rgba(accent.r, accent.g, accent.b, 0.09)
  readonly property color cardBorder: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
  readonly property color graphGrid: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
  readonly property color track: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
  readonly property color barTrack: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
  readonly property color headroomColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: (bar && bar.fontFamily) ? bar.fontFamily : Style.font.family

  // Responsive Typography with guaranteed floor >= 10px
  readonly property int fontCaption: Math.max(10, Style.font.caption)
  readonly property int fontSmall:   Math.max(10, Style.font.bodySmall)
  readonly property int fontBody:    Math.max(11, Style.font.body)
  readonly property int fontTitle:   Math.max(12, Style.font.title)
  readonly property int fontHeading: Math.max(14, Style.font.heading)
  readonly property int fontDisplay: Math.max(16, Style.font.display)

  // Tab navigation
  property int selectedTab: 0 // 0: Performance & Limits, 1: Sessions & Tools, 2: Settings

  // Python Scanner process
  readonly property string scannerScriptPath: Qt.resolvedUrl("scripts/antigravity_scanner.py").toString().replace(/^file:\/\//, "")
  property bool refreshing: false
  Process {
    id: scannerProcess
    command: ["python3", root.scannerScriptPath]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyUsage(text)
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: function(text) {
        if (text && text.trim() !== "") console.warn("simonez.antigem/scanner:", text.trim())
      }
    }

    onExited: {
      root.refreshing = false
    }
  }

  function applyUsage(content) {
    try {
      var data = JSON.parse(String(content || "{}"))
      if (!data || !data.ready) return

      var wasWorking = root.isWorking

      root.ready = true
      root.active = data.active === true
      root.activeStatus = String(data.activeStatus || "Idle")
      root.tierLabel = String(data.tierLabel || "Google AI Pro")
      root.currentModel = String(data.currentModel || "Gemini 3.8 Flash")
      root.activeVersion = String(data.activeVersion || data.serverVersion || "CLI v1.1.26")
      root.serverVersion = String(data.serverVersion || "CLI v1.1.26")
      root.serverVersionFull = String(data.serverVersionFull || "CLI v1.1.26")
      root.todayPrompts = Number(data.todayPrompts || 0)
      root.totalPrompts = Number(data.totalPrompts || 0)
      root.recentDays = data.recentDays || []
      root.toolsList = data.tools || []
      root.recentSessions = data.recentSessions || []
      root.featuredSessions = (data.featuredSessions && data.featuredSessions.length > 0) ? data.featuredSessions : ((data.recentSessions && data.recentSessions.length > 0) ? data.recentSessions.slice(0, 2) : [])
      root.gcpInfo = data.gcpApis || null
      root.localAiInfo = data.localAi || null
      root.subagentsFleet = data.subagentsFleet || []
      root.subagentProfiler = data.subagentProfiler || []

      root.contextPct = Number(data.contextPct || 0)
      root.contextTokensStr = String(data.contextTokensStr || "0k / 1M")
      root.contextMap = data.contextMap || ({})
      root.activeSubagents = Number(data.activeSubagents || 0)
      root.productivityData = data.productivity || {}
      root.quotasBreakdown = data.quotasBreakdown || ({})
      root.activityBreakdown = data.activityBreakdown || ({})

      // Feature 2: Task Completion Desktop Notification
      if (root.notificationsEnabled && wasWorking && !root.isWorking && root.activeStatus !== "Working") {
        if (root.bar && typeof root.bar.run === "function") {
          root.bar.run("notify-send -a 'Antigravity' -i 'dialog-information' 'Antigravity AI' '✅ Task complete! All changes and tests are finished.'")
        }
      }

      if (data.tokens) {
        root.tokensData = data.tokens
        root.weeklyTokensUsed = String(data.tokens.weeklyUsedStr || "~24.5M")
        root.weeklyTokensRemaining = String(data.tokens.weeklyRemainingStr || "~500k")
        root.weeklyTokensRemainingPct = Number(data.tokens.weeklyRemainingPct || 2)
        root.weeklyTokensDetail = String(data.tokens.weeklyDetail || "Resets in ~1d 15h")
        root.weeklyTokensSeverity = String(data.tokens.weeklySeverity || "normal")
        root.sessionTokensUsed = String(data.tokens.sessionUsedStr || "~75k")
        root.sessionTokensRemaining = String(data.tokens.sessionRemainingStr || "~2.42M")
        root.todayTokens = String(data.tokens.todayTokensStr || "~285k")
        root.allTimeTokens = String(data.tokens.allTimeTokensStr || "~48.6M")
      }

      if (data.quotas) {
        if (data.quotas.session) {
          root.sessionGeminiPct = Number(data.quotas.session.percent || 0)
          root.sessionGeminiDetail = String(data.quotas.session.detail || "")
        }
        if (data.quotas.weekly) {
          root.weeklyGeminiPct = Number(data.quotas.weekly.percent || 0)
          root.weeklyGeminiDetail = String(data.quotas.weekly.detail || "")
        }
        if (data.quotas.autoFailover) {
          root.autoFailoverInfo = data.quotas.autoFailover
        }
      }
    } catch (e) {
      console.error("simonez.antigem: Parse error", e)
    }
  }

  function copySessionSummary(s) {
    if (!s) return
    var title = s.title || s.firstPrompt || "Antigravity Session"
    var date = s.date || "-"
    var cid = s.conversationId || s.id || ""
    var ws = s.workspace || "~"
    var client = (s.clientType || "cli").toUpperCase()
    var md = "### 🤖 Antigravity Session: " + title + "\n" +
             "- **ID:** `" + cid + "`\n" +
             "- **Date:** " + date + " (" + (s.timeAgo || "") + ")\n" +
             "- **Client:** " + client + "\n" +
             "- **Workspace:** `" + ws + "`\n"
    if (typeof Quickshell !== "undefined" && typeof Quickshell.execDetached === "function") {
      Quickshell.execDetached(["/usr/bin/wl-copy", md])
    } else if (root.bar && typeof root.bar.run === "function") {
      root.bar.run(["/usr/bin/wl-copy", md])
    }
  }

  function setNotificationsEnabled(enabled) {
    root.notificationsEnabled = enabled
    var entry = { id: root.moduleName }
    if (root.settings && typeof root.settings === "object") {
      for (var key in root.settings) {
        if (key !== "id") entry[key] = root.settings[key]
      }
    }
    entry["notificationsEnabled"] = enabled
    root.settings = entry

    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    }
  }

  property int refreshIntervalSec: Number(root.setting("refreshIntervalSec", 60))
  property int secondsRemaining: Number(root.setting("refreshIntervalSec", 60))
  property bool pulseEnabled: root.setting("pulseEnabled", true) !== false
  property int pulseBpm: Math.max(20, Math.min(240, Number(root.setting("pulseBpm", 60)) || 60))

  readonly property int pulseCycleMs: Math.round(60000 / Math.max(20, root.pulseBpm))
  readonly property int pulseT1Up: Math.max(30, Math.round(pulseCycleMs * 0.105))
  readonly property int pulseT1Down: Math.max(30, Math.round(pulseCycleMs * 0.115))
  readonly property int pulseT2Up: Math.max(25, Math.round(pulseCycleMs * 0.095))
  readonly property int pulseT2Down: Math.max(30, Math.round(pulseCycleMs * 0.125))
  readonly property int pulsePause: Math.max(30, pulseCycleMs - (pulseT1Up + pulseT1Down + pulseT2Up + pulseT2Down))

  onSettingsChanged: {
    var configured = Number(root.setting("refreshIntervalSec", 60))
    if (!isNaN(configured) && configured >= 5 && configured !== root.refreshIntervalSec) {
      root.refreshIntervalSec = configured
      root.secondsRemaining = configured
    }
    var pe = root.setting("pulseEnabled", true) !== false
    if (pe !== root.pulseEnabled) root.pulseEnabled = pe
    var bpm = Number(root.setting("pulseBpm", 60))
    if (!isNaN(bpm) && bpm >= 20 && bpm <= 240 && bpm !== root.pulseBpm) root.pulseBpm = bpm
  }

  function setPulseEnabled(enabled) {
    root.pulseEnabled = enabled
    var entry = { id: root.moduleName }
    if (root.settings && typeof root.settings === "object") {
      for (var key in root.settings) {
        if (key !== "id") entry[key] = root.settings[key]
      }
    }
    entry["pulseEnabled"] = enabled
    root.settings = entry

    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    }
  }

  function setPulseBpm(bpm) {
    var val = parseInt(bpm, 10)
    if (isNaN(val) || val < 20) val = 20
    if (val > 240) val = 240
    root.pulseBpm = val

    var entry = { id: root.moduleName }
    if (root.settings && typeof root.settings === "object") {
      for (var key in root.settings) {
        if (key !== "id") entry[key] = root.settings[key]
      }
    }
    entry["pulseBpm"] = val
    root.settings = entry

    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    }
  }

  function setRefreshInterval(seconds) {
    var val = parseInt(seconds, 10)
    if (isNaN(val) || val < 5) val = 5
    if (val > 3600) val = 3600

    root.refreshIntervalSec = val
    root.secondsRemaining = val

    var entry = { id: root.moduleName }
    if (root.settings && typeof root.settings === "object") {
      for (var key in root.settings) {
        if (key !== "id") entry[key] = root.settings[key]
      }
    }
    entry["refreshIntervalSec"] = val
    root.settings = entry

    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    }
  }

  property bool manualRefreshing: false

  Timer {
    id: manualRefreshFeedbackTimer
    interval: 850
    repeat: false
    onTriggered: root.manualRefreshing = false
  }

  function triggerManualRefresh() {
    root.manualRefreshing = true
    manualRefreshFeedbackTimer.restart()
    root.requestRefresh()
  }

  function requestRefresh() {
    if (root.refreshing) return
    root.refreshing = true
    root.secondsRemaining = root.refreshIntervalSec
    scannerProcess.running = true
  }

  function triggerPress(buttonCode) {
    if (buttonCode === 1 || buttonCode === Qt.LeftButton) { // Left click
      if (!root.opened) {
        root.selectedTab = 0 // Reset to primary performance tab on fresh open
      }
      root.toggle()
    } else if (buttonCode === 3 || buttonCode === Qt.RightButton) { // Right click
      root.selectedTab = 2
      root.open()
    } else if (buttonCode === 2 || buttonCode === Qt.MiddleButton) { // Middle click
      root.triggerManualRefresh()
    }
  }

  function open() {
    root.opened = true
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    root.opened = false
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  function toggle() {
    root.opened ? root.close() : root.open()
  }

  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) {
      panelLoader.item.closeForPopoutSwitch()
    } else {
      root.close()
    }
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  IpcHandler {
    target: "simonez.antigem"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function selectTab(tab: int): void {
      root.open()
      root.selectedTab = tab
    }
  }

  // Initial startup delay timer to let Quickshell finish layout before spawning Python scanner
  Timer {
    id: initialStartupTimer
    interval: 400
    running: false
    repeat: false
    onTriggered: root.requestRefresh()
  }





  // Fast live telemetry polling: active only when panel is open or agent is working/waiting
  Timer {
    interval: 2000
    running: root.popupOpen || root.isWorking || root.isWaiting
    repeat: true
    onTriggered: {
      if (!root.refreshing) {
        root.refreshing = true
        scannerProcess.running = true
      }
    }
  }

  // Main interval countdown timer
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      if (root.secondsRemaining > 0) {
        root.secondsRemaining -= 1
      } else {
        root.requestRefresh()
      }
    }
  }

  Component.onCompleted: {
    initialStartupTimer.start()
  }

  // Top Bar Chip Tooltip
  readonly property string barTooltip: {
    var text = "Antigravity — Google AI Pro"
    text += "\n⏱ 5h Session: " + root.sessionGeminiPct + "% (" + root.sessionTokensUsed + " · " + root.sessionGeminiDetail + ")"
    text += "\n📅 7d Weekly: " + root.weeklyGeminiPct + "% (" + root.weeklyTokensUsed + " / 25M · " + (root.weeklyGeminiPct >= 90 ? "🚨 CRITICAL LIMIT! Remaining " + root.weeklyTokensRemaining : root.weeklyGeminiDetail) + ")"
    text += "\n🪙 Today Tokens: " + root.todayTokens + " (Total: " + root.allTimeTokens + ")"
    text += "\n🧠 Model: " + root.currentModel
    text += "\n⚙️ Client: " + (root.activeVersion || root.serverVersion)
    text += "\nStatus: " + (root.isWorking ? "Working 💓" : (root.isWaiting ? "Waiting for input" : "Idle"))
    text += "\n[Tap: Open panel · Right-tap: Settings]"
    return text
  }

  implicitWidth: contentRow.implicitWidth + button.scaledHorizontalMargin * 2
  implicitHeight: button.implicitHeight

  // Top Bar Chip (System Monitor Instrument Presentation)
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "Antigravity"
    labelVisible: false
    keepSpace: true
    hasVisualContent: true
    fixedWidth: contentRow.implicitWidth + button.scaledHorizontalMargin * 2
    tooltipText: root.barTooltip
    horizontalMargin: 8.5

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.space(4)

      // 1. Antigravity Logo with Heartbeat Pulse
      Image {
        id: barAppLogo
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        sourceSize.width: 24
        sourceSize.height: 24
        source: root.appIconPath
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true
        transformOrigin: Item.Center

        SequentialAnimation {
          id: barHeartbeatAnim
          running: root.isWorking && root.pulseEnabled
          loops: Animation.Infinite
          onRunningChanged: {
            if (!running) barAppLogo.scale = 1.0
          }

          NumberAnimation { target: barAppLogo; property: "scale"; to: 1.35; duration: root.pulseT1Up; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
          NumberAnimation { target: barAppLogo; property: "scale"; to: 1.0; duration: root.pulseT1Down; easing.type: Easing.InOutQuad }
          NumberAnimation { target: barAppLogo; property: "scale"; to: 1.25; duration: root.pulseT2Up; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
          NumberAnimation { target: barAppLogo; property: "scale"; to: 1.0; duration: root.pulseT2Down; easing.type: Easing.InOutQuad }
          PauseAnimation { duration: root.pulsePause }
        }
      }

      // 2. 5h Session Quota Value (White font / Live heartbeat)
      Text {
        id: barPctText
        anchors.verticalCenter: parent.verticalCenter
        text: root.sessionGeminiPct + "%"
        color: root.isWorking ? root.uploadColor : (root.sessionGeminiPct > 80 ? root.criticalColor : root.foreground)
        font.family: root.fontFamily
        font.pixelSize: root.fontCaption
        renderType: Text.NativeRendering

        SequentialAnimation {
          id: barTextHeartbeatAnim
          running: root.isWorking && root.pulseEnabled
          loops: Animation.Infinite
          onRunningChanged: {
            if (!running) barPctText.scale = 1.0
          }

          NumberAnimation { target: barPctText; property: "scale"; to: 1.15; duration: root.pulseT1Up; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
          NumberAnimation { target: barPctText; property: "scale"; to: 1.0; duration: root.pulseT1Down; easing.type: Easing.InOutQuad }
          NumberAnimation { target: barPctText; property: "scale"; to: 1.10; duration: root.pulseT2Up; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
          NumberAnimation { target: barPctText; property: "scale"; to: 1.0; duration: root.pulseT2Down; easing.type: Easing.InOutQuad }
          PauseAnimation { duration: root.pulsePause }
        }
      }
    }

    onPressed: function(buttonCode) {
      root.triggerPress(buttonCode)
    }
  }

  // =========================================================================
  // POPUP LAZY LOADER (Omarchy Standard Architecture)
  // =========================================================================
  property alias anchorButton: button

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }
}
