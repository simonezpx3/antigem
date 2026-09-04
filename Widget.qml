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
  property string currentModel: "Gemini 3.8 Flash (High)"
  property string serverVersion: "v2.10.0"
  property string serverVersionFull: "v2.10.0 (CLI 1.1.25)"
  property int sessionGeminiPct: 0
  property string sessionGeminiDetail: "Resets in ~5h"
  property int weeklyGeminiPct: 0
  property string weeklyGeminiDetail: "Resets in ~7d"

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
    if (name.indexOf("headroom") !== -1 || name.indexOf("volný") !== -1) return root.headroomColor
    if (name.indexOf("code") !== -1 || name.indexOf("kód") !== -1 || name.indexOf("today") !== -1 || name.indexOf("dnes") !== -1 || name.indexOf("security") !== -1 || name.indexOf("sec-auditor") !== -1 || name.indexOf("chat") !== -1 || name.indexOf("history") !== -1) return root.uploadColor
    if (name.indexOf("term") !== -1 || name.indexOf("command") !== -1 || name.indexOf("příkaz") !== -1 || name.indexOf("test") !== -1) return root.loadColor
    if (name.indexOf("search") !== -1 || name.indexOf("hled") !== -1 || name.indexOf("navig") !== -1 || name.indexOf("tool") !== -1 || name.indexOf("nástroj") !== -1 || name.indexOf("mcp") !== -1 || name.indexOf("qml") !== -1 || name.indexOf("session") !== -1) return root.primaryAccent
    if (name.indexOf("arch") !== -1 || name.indexOf("plan") !== -1 || name.indexOf("syst") !== -1 || name.indexOf("rule") !== -1 || name.indexOf("pravid") !== -1 || name.indexOf("doc") !== -1 || name.indexOf("prior") !== -1 || name.indexOf("minul") !== -1) return root.memoryColor
    if (name.indexOf("file") !== -1 || name.indexOf("soubor") !== -1) return root.downloadColor
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
      root.currentModel = String(data.currentModel || "Gemini 3.8 Flash (High)")
      root.serverVersion = String(data.serverVersion || "v2.10.0")
      root.serverVersionFull = String(data.serverVersionFull || "v2.10.0 (CLI 1.1.25)")
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
          root.bar.run("notify-send -a 'Antigravity' -i 'dialog-information' 'Antigravity AI' '✅ Úkol dokončen! Všechny změny a testy jsou hotové.'")
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
  }

  function close() {
    root.opened = false
  }

  function toggle() {
    root.opened ? root.close() : root.open()
  }

  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    root.close()
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
    text += "\n⚙️ AGY Server: " + root.serverVersionFull
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
        font.pixelSize: Style.font.caption
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

  // System Monitor Main Dashboard Popup Panel
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    onOpenChanged: {
      if (open !== root.opened) root.opened = open
      if (open) {
        root.requestRefresh()
      }
    }
    contentWidth: panel.fittedContentWidth(Style.space(560))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight, Style.space(850))

    Flickable {
      id: flick
      anchors.fill: parent
      contentWidth: width
      contentHeight: mainCol.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: mainCol
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        spacing: Style.space(10)

        // 1. Panel Hero Header (System Monitor style)
        Rectangle {
          width: parent.width
          implicitHeight: Math.max(62, headerHeroLayout.implicitHeight + Style.space(8))
          radius: 8
          color: root.cardFill
          border.color: root.cardBorder
          border.width: 1

          RowLayout {
            id: headerHeroLayout
            anchors.fill: parent
            anchors.margins: Style.space(6)
            spacing: Style.space(8)

            // App Icon Container (Frameless)
            Item {
              width: 38
              height: 38

              Image {
                id: heroAppLogo
                anchors.fill: parent
                source: root.appIconPanelPath
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
              }
            }

            // Title & Subtitle Meta
            Column {
              Layout.fillWidth: true
              spacing: 3

              Text {
                id: headerTitleText
                text: "Antigravity"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.heading
                font.bold: true
              }

              Text {
                text: root.tierLabel.toUpperCase() + " · TELEMETRY & QUOTAS"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
            }
          }
        }

        // 2. Navigation Tabs (System Monitor style)
        Row {
          id: tabsRow
          width: parent.width
          spacing: Style.space(3)

          readonly property real tabWidth: (width - spacing * 2) / 3

          Repeater {
            model: [
              { title: root.t("tabPerf", "Performance"), tabIndex: 0 },
              { title: root.t("tabSessions", "Sessions & Tools"), tabIndex: 1 },
              { title: root.t("tabSettings", "Settings"), tabIndex: 2 }
            ]

            Rectangle {
              height: 28
              width: tabsRow.tabWidth
              radius: 6
              scale: tabMouse.pressed ? 0.92 : 1.0
              color: tabMouse.containsMouse ? root.cardHover : root.cardFill
              border.color: (root.selectedTab === modelData.tabIndex) 
                            ? root.primaryAccent 
                            : (tabMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.28) : root.cardBorder)
              border.width: 1

              Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                text: modelData.title
                color: (root.selectedTab === modelData.tabIndex) ? root.foreground : (tabMouse.containsMouse ? root.foreground : root.dim)
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: root.selectedTab === modelData.tabIndex
              }

              MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedTab = modelData.tabIndex
                  if (modelData.tabIndex === 2) {
                    omarchyLogoBox.startLightningDischarge()
                  }
                }
              }
            }
          }
        }

        // 3. TAB 0: Performance & Limits (Quotas & Sparkline)
        Column {
          visible: root.selectedTab === 0
          width: parent.width
          spacing: Style.space(10)

          // Critical Token Warning Banner (when weekly tokens are >= 90%)
          Rectangle {
            visible: root.weeklyGeminiPct >= 90
            width: parent.width
            height: 34
            radius: 6
            color: Qt.rgba(root.criticalColor.r, root.criticalColor.g, root.criticalColor.b, 0.18)
            border.color: root.criticalColor
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              spacing: Style.space(4)

              Text {
                text: "🚨"
                font.pixelSize: Style.font.body
              }

              Text {
                text: "CRITICAL LIMIT: Only " + (100 - root.weeklyGeminiPct) + "% weekly tokens left (" + root.weeklyTokensRemaining + ")! Reset in " + root.weeklyGeminiDetail
                color: root.criticalColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }
          }

          // 1. Google AI Pro Quotas Breakdown Card
          Rectangle {
            width: parent.width
            implicitHeight: quotasCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.weeklyGeminiPct >= 90 ? root.criticalColor : root.cardBorder
            border.width: 1

            readonly property var sessionSegments: (root.quotasBreakdown && root.quotasBreakdown.session && root.quotasBreakdown.session.segments && root.quotasBreakdown.session.segments.length > 0)
              ? root.quotasBreakdown.session.segments
              : [
                  { name: "Session Used", tokensStr: root.sessionTokensUsed, pct: root.sessionGeminiPct, color: "#06b6d4" },
                  { name: "Free Headroom", tokensStr: root.sessionTokensRemaining, pct: Math.max(0, 100 - root.sessionGeminiPct), color: root.headroomColor }
                ]

            readonly property var weeklySegments: (root.quotasBreakdown && root.quotasBreakdown.weekly && root.quotasBreakdown.weekly.segments && root.quotasBreakdown.weekly.segments.length > 0)
              ? root.quotasBreakdown.weekly.segments
              : [
                  { name: "Today Tokens", tokensStr: root.todayTokens, pct: Math.round((root.weeklyGeminiPct * 0.12) * 10) / 10, color: "#10b981" },
                  { name: "Prior 6 Days", tokensStr: root.weeklyTokensUsed, pct: Math.round((root.weeklyGeminiPct * 0.88) * 10) / 10, color: "#a855f7" },
                  { name: "Free Headroom", tokensStr: root.weeklyTokensRemaining, pct: Math.max(0, 100 - root.weeklyGeminiPct), color: root.headroomColor }
                ]

            Column {
              id: quotasCardCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(4)

              // Header
              RowLayout {
                width: parent.width

                Text {
                  Layout.fillWidth: true
                  text: root.t("quotasTitle", "📊 GOOGLE AI PRO QUOTAS")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }

                Rectangle {
                  height: 20
                  implicitWidth: headerPillRow.implicitWidth + 12
                  radius: 4
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                  border.color: root.cardBorder
                  border.width: 1

                  Row {
                    id: headerPillRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                      text: root.tierLabel
                      color: root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }

                    Text {
                      text: "·"
                      color: root.dim
                      font.pixelSize: Style.font.caption
                    }

                    Text {
                      text: root.weeklyGeminiDetail
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }

              // Compact Token Sums (4 Badges)
              RowLayout {
                width: parent.width
                spacing: Style.space(3)

                Rectangle {
                  Layout.fillWidth: true
                  height: 36
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.cardBorder
                  border.width: 1
                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text { text: "TODAY TOKENS"; color: root.dim; font.pixelSize: Style.font.caption - 1; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.todayTokens; color: root.cpuColor; font.bold: true; font.pixelSize: Style.font.bodySmall; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  height: 36
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.cardBorder
                  border.width: 1
                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text { text: "TODAY PROMPTS"; color: root.dim; font.pixelSize: Style.font.caption - 1; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: String(root.todayPrompts); color: root.primaryAccent; font.bold: true; font.pixelSize: Style.font.bodySmall; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  height: 36
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.weeklyGeminiPct >= 90 ? root.criticalColor : root.cardBorder
                  border.width: 1
                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text { text: "HEADROOM (7D)"; color: root.dim; font.pixelSize: Style.font.caption - 1; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.weeklyTokensRemaining; color: root.weeklyGeminiPct >= 90 ? root.criticalColor : root.uploadColor; font.bold: true; font.pixelSize: Style.font.bodySmall; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  height: 36
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.cardBorder
                  border.width: 1
                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text { text: "ALL-TIME TOKENS"; color: root.dim; font.pixelSize: Style.font.caption - 1; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.allTimeTokens; color: root.foreground; font.bold: true; font.pixelSize: Style.font.bodySmall; font.family: root.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                  }
                }
              }

              // 5H Session Quota Stacked Bar
              Column {
                width: parent.width
                spacing: 3

                RowLayout {
                  width: parent.width
                  Text {
                    text: "⏱ 5H SESSION QUOTA (2.5M CAP)"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: root.sessionTokensUsed + " / 2.5M (" + root.sessionGeminiPct + "%) · " + root.sessionGeminiDetail
                    color: root.cpuColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption - 1
                    font.bold: true
                  }
                }

                Rectangle {
                  width: parent.width
                  height: 8
                  radius: 4
                  color: root.barTrack
                  clip: true
                  Row {
                    anchors.fill: parent
                    spacing: 1
                    Repeater {
                      model: quotasCardCol.parent.sessionSegments
                      Rectangle {
                        height: parent.height
                        width: Math.max(modelData.pct > 0 ? 3 : 0, (parent.width * (Number(modelData.pct || 0) / 100.0)))
                        color: root.resolveSegmentColor(modelData, root.primaryAccent)
                      }
                    }
                  }
                }

                Flow {
                  width: parent.width
                  spacing: Style.space(6)
                  Repeater {
                    model: quotasCardCol.parent.sessionSegments
                    Row {
                      spacing: 4
                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 2
                        color: root.resolveSegmentColor(modelData, root.primaryAccent)
                      }
                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name + " (" + modelData.tokensStr + " · " + modelData.pct + "%)"
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: 8
                      }
                    }
                  }
                }
              }

              // 7D Weekly Quota Stacked Bar
              Column {
                width: parent.width
                spacing: 3

                RowLayout {
                  width: parent.width
                  Text {
                    text: "📅 7D WEEKLY QUOTA (25.0M CAP)"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: root.weeklyTokensUsed + " / 25.0M (" + root.weeklyGeminiPct + "%) · " + root.weeklyGeminiDetail
                    color: root.weeklyGeminiPct >= 90 ? root.criticalColor : root.memoryColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption - 1
                    font.bold: true
                  }
                }

                Rectangle {
                  width: parent.width
                  height: 8
                  radius: 4
                  color: root.barTrack
                  clip: true
                  Row {
                    anchors.fill: parent
                    spacing: 1
                    Repeater {
                      model: quotasCardCol.parent.weeklySegments
                      Rectangle {
                        height: parent.height
                        width: Math.max(modelData.pct > 0 ? 3 : 0, (parent.width * (Number(modelData.pct || 0) / 100.0)))
                        color: root.resolveSegmentColor(modelData, root.primaryAccent)
                      }
                    }
                  }
                }

                Flow {
                  width: parent.width
                  spacing: Style.space(6)
                  Repeater {
                    model: quotasCardCol.parent.weeklySegments
                    Row {
                      spacing: 4
                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 2
                        color: root.resolveSegmentColor(modelData, root.primaryAccent)
                      }
                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name + " (" + modelData.tokensStr + " · " + modelData.pct + "%)"
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: 8
                      }
                    }
                  }
                }
              }
            }
          }

          // 2. 7-Day Activity Trend Card (AntigemS Sparkline Style)
          Rectangle {
            width: parent.width
            implicitHeight: activityCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: activityCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  Layout.fillWidth: true
                  text: root.t("activityTrendTitle", "📈 PROMPTS & TOOL CALLS TREND (7 DAYS)")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  text: (root.todayPrompts || 0) + " today · " + (root.totalPrompts || 0) + " total"
                  color: root.primaryAccent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // Sparkline Canvas
              Canvas {
                id: sparkCanvas
                width: parent.width
                height: 60

                readonly property var recentDays: (root.recentDays && root.recentDays.length > 0) ? root.recentDays : []
                onRecentDaysChanged: requestPaint()
                Component.onCompleted: requestPaint()

                onPaint: {
                  var ctx = getContext("2d")
                  ctx.clearRect(0, 0, width, height)

                  var days = recentDays
                  if (!days || days.length < 2) return

                  var maxP = 1
                  for (var i = 0; i < days.length; i++) {
                    var p = Number(days[i].prompts || 0)
                    if (p > maxP) maxP = p
                  }

                  var stepX = width / (days.length - 1)
                  var padY = 8
                  var availH = height - padY * 2

                  // Background Area Gradient
                  var grad = ctx.createLinearGradient(0, 0, 0, height)
                  grad.addColorStop(0, Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.28))
                  grad.addColorStop(1, Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.01))

                  ctx.beginPath()
                  for (var j = 0; j < days.length; j++) {
                    var px = j * stepX
                    var py = height - padY - (Number(days[j].prompts || 0) / maxP) * availH
                    if (j === 0) ctx.moveTo(px, py)
                    else ctx.lineTo(px, py)
                  }
                  ctx.lineTo(width, height)
                  ctx.lineTo(0, height)
                  ctx.closePath()
                  ctx.fillStyle = grad
                  ctx.fill()

                  // Foreground Polyline
                  ctx.beginPath()
                  for (var k = 0; k < days.length; k++) {
                    var kx = k * stepX
                    var ky = height - padY - (Number(days[k].prompts || 0) / maxP) * availH
                    if (k === 0) ctx.moveTo(kx, ky)
                    else ctx.lineTo(kx, ky)
                  }
                  ctx.strokeStyle = root.primaryAccent
                  ctx.lineWidth = 2.0
                  ctx.stroke()

                  // Data Points
                  for (var m = 0; m < days.length; m++) {
                    var mx = m * stepX
                    var my = height - padY - (Number(days[m].prompts || 0) / maxP) * availH
                    ctx.beginPath()
                    ctx.arc(mx, my, 3, 0, 2 * Math.PI)
                    ctx.fillStyle = m === days.length - 1 ? root.uploadColor : root.primaryAccent
                    ctx.fill()
                    ctx.strokeStyle = root.cardFill
                    ctx.lineWidth = 1.5
                    ctx.stroke()
                  }
                }
              }

              // Day labels row
              Row {
                width: parent.width
                spacing: 0
                readonly property var days: (root.recentDays && root.recentDays.length > 0) ? root.recentDays : []
                Repeater {
                  model: parent.days
                  Item {
                    width: sparkCanvas.width / Math.max(1, parent.days.length)
                    height: 16
                    Text {
                      anchors.centerIn: parent
                      text: {
                        var d = String(modelData.date || "")
                        var parts = d.split("-")
                        var dateStr = parts.length >= 3 ? parts[1] + "/" + parts[2] : d
                        return dateStr
                      }
                      color: index === parent.days.length - 1 ? root.primaryAccent : root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                      font.bold: index === parent.days.length - 1
                    }
                  }
                }
              }
            }
          }

          // 3. 1M Context Window Breakdown Card
          Rectangle {
            width: parent.width
            implicitHeight: contextCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            readonly property var contextSegments: (root.contextMap && root.contextMap.segments && root.contextMap.segments.length > 0)
              ? root.contextMap.segments
              : [
                  { name: "System & Rules", tokensStr: "8.5k", pct: 0.85, color: "#a855f7" },
                  { name: "Tool Schemas", tokensStr: "14.2k", pct: 1.42, color: "#06b6d4" },
                  { name: "File Context", tokensStr: "43.2k", pct: 4.32, color: "#3b82f6" },
                  { name: "Chat History", tokensStr: "12.0k", pct: 1.20, color: "#10b981" },
                  { name: "Free Headroom", tokensStr: "922.1k", pct: 92.21, color: root.headroomColor }
                ]

            Column {
              id: contextCardCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                spacing: Style.space(3)

                Text {
                  Layout.fillWidth: true
                  text: root.t("contextBreakdownTitle", "🧠 1M CONTEXT WINDOW BREAKDOWN")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }

                Text {
                  text: (root.contextMap && root.contextMap.usedStr ? root.contextMap.usedStr : root.contextTokensStr) + " / 1.0M (" + (root.contextMap && root.contextMap.usedPct ? root.contextMap.usedPct : root.contextPct) + "%)"
                  color: root.primaryAccent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // Multi-segment Stacked Horizontal Bar
              Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: root.barTrack
                clip: true

                Row {
                  anchors.fill: parent
                  spacing: 1

                  Repeater {
                    model: contextCardCol.parent.contextSegments

                    Rectangle {
                      height: parent.height
                      width: Math.max(modelData.pct > 0 ? 3 : 0, (parent.width * (Number(modelData.pct || 0) / 100.0)))
                      color: root.resolveSegmentColor(modelData, root.primaryAccent)
                    }
                  }
                }
              }

              // Context Segments Legend Grid
              Flow {
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: contextCardCol.parent.contextSegments

                  Row {
                    spacing: 4
                    Rectangle {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 8
                      height: 8
                      radius: 2
                      color: root.resolveSegmentColor(modelData, root.primaryAccent)
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.name + " (" + modelData.tokensStr + " · " + modelData.pct + "%)"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                    }
                  }
                }
              }
            }
          }

          // 4. Developer Productivity & Time Saved Breakdown Card
          Rectangle {
            width: parent.width
            implicitHeight: prodCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            property var prodSegments: {
              if (root.productivityData && root.productivityData.segments && root.productivityData.segments.length > 0) {
                return root.productivityData.segments;
              }
              return [
                { "name": "Code Generation & Edits", "hoursStr": "79.2h", "pct": 29.2, "color": "#10b981" },
                { "name": "Terminal & Commands", "hoursStr": "85.0h", "pct": 31.4, "color": "#f59e0b" },
                { "name": "Search & Navigation", "hoursStr": "79.2h", "pct": 29.2, "color": "#06b6d4" },
                { "name": "Architecture & Planning", "hoursStr": "27.7h", "pct": 10.2, "color": "#a855f7" }
              ];
            }

            Column {
              id: prodCardCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(4)

              RowLayout {
                width: parent.width

                Text {
                  Layout.fillWidth: true
                  text: root.t("prodTitle", "⚡ DEV PRODUCTIVITY & TIME SAVED")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }

                Text {
                  text: (root.productivityData && root.productivityData.timeSavedStr ? root.productivityData.timeSavedStr : "~271h saved") + " (" + (root.productivityData && root.productivityData.toolsExecuted ? root.productivityData.toolsExecuted : 6906) + " tools)"
                  color: root.uploadColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // Multi-segment Stacked Horizontal Bar
              Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: root.barTrack
                clip: true

                Row {
                  anchors.fill: parent
                  spacing: 1

                  Repeater {
                    model: prodCardCol.parent.prodSegments

                    Rectangle {
                      height: parent.height
                      width: Math.max(modelData.pct > 0 ? 3 : 0, (parent.width * (Number(modelData.pct || 0) / 100.0)))
                      color: root.resolveSegmentColor(modelData, root.primaryAccent)
                    }
                  }
                }
              }

              // Productivity Segments Legend Grid
              Flow {
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: prodCardCol.parent.prodSegments

                  Row {
                    spacing: 4
                    Rectangle {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 8
                      height: 8
                      radius: 2
                      color: root.resolveSegmentColor(modelData, root.primaryAccent)
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.name + " (" + modelData.hoursStr + " · " + modelData.pct + "%)"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                    }
                  }
                }
              }
            }
          }

          // 5. GCP & Cloud APIs Availability Card
          Rectangle {
            width: parent.width
            implicitHeight: gcpCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: gcpCardCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              // Header Row
              Item {
                width: parent.width
                implicitHeight: 22

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.t("gcpTitle", "☁️ GOOGLE CLOUD & APIS")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
              }

              // Top Stats Banner Row (Latency / Region / SLA Uptime)
              RowLayout {
                width: parent.width
                spacing: Style.space(4)

                // Metric 1: Latency
                Rectangle {
                  Layout.fillWidth: true
                  height: 38
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.color: root.cardBorder
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: (root.gcpInfo && root.gcpInfo.latencyMs ? (root.gcpInfo.latencyMs + " ms") : "30 ms")
                      color: root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "API Latency"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }

                // Metric 2: Region / Routing
                Rectangle {
                  Layout.fillWidth: true
                  height: 38
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.color: root.cardBorder
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: (root.gcpInfo && root.gcpInfo.region) ? root.gcpInfo.region : "europe-west (CZ)"
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "Edge Region"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }

                // Metric 3: Availability / Uptime
                Rectangle {
                  Layout.fillWidth: true
                  height: 38
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.color: root.cardBorder
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: (root.gcpInfo && root.gcpInfo.uptime) ? root.gcpInfo.uptime : "99.98%"
                      color: root.uploadColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "SLA Uptime"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }

              // Service & API Endpoints Table
              Repeater {
                model: (root.gcpInfo && root.gcpInfo.services && root.gcpInfo.services.length > 0) ? root.gcpInfo.services : [
                  { name: "Gemini 3.8 Flash / Pro (Interactions API)", endpoint: "generativelanguage.googleapis.com", status: "Operational", latency: "30 ms", tag: "Live Chat, Tools & Code" },
                  { name: "Google Grounding & Web Search", endpoint: "search.googleapis.com", status: "Operational", latency: "27 ms", tag: "Live Docs & Web Index" },
                  { name: "Codebase Embeddings & Semantic Index", endpoint: "generativelanguage.googleapis.com/embeddings", status: "Operational", latency: "32 ms", tag: "Vector RAG & Brain Search" },
                  { name: "Cloud Code & Multi-Agent Fleet", endpoint: "aiplatform.googleapis.com", status: "Operational", latency: "33 ms", tag: "Agent Protocol & Tool Sync" }
                ]

                Rectangle {
                  width: parent.width
                  height: 32
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.02)
                  border.color: root.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(4)
                    spacing: Style.space(4)

                    // Status Indicator Dot
                    Rectangle {
                      width: 7
                      height: 7
                      radius: 3.5
                      color: (modelData.status === "Operational" || modelData.status === "Online") ? root.uploadColor : (modelData.status === "Ready" ? root.primaryAccent : root.dim)
                    }

                    // API Name & Tag
                    Column {
                      Layout.fillWidth: true
                      spacing: 0

                      Text {
                        text: modelData.name
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                      }

                      Text {
                        text: {
                          var ep = modelData.endpoint || ""
                          var tg = modelData.tag || modelData.badge || ""
                          if (ep && tg) return ep + " · " + tg
                          if (ep) return ep
                          if (tg) return tg
                          return "googleapis.com · Active"
                        }
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption - 1
                        elide: Text.ElideRight
                        width: parent.width
                      }
                    }

                    // Latency / Status Badge
                    Rectangle {
                      height: 18
                      width: svcLatText.implicitWidth + 10
                      radius: 3
                      color: root.barTrack

                      Text {
                        id: svcLatText
                        anchors.centerIn: parent
                        text: modelData.latency || modelData.ping || "30 ms"
                        color: root.primaryAccent
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // 4. TAB 1: Sessions & Tools (Relace & Nástroje)
        Column {
          visible: root.selectedTab === 1
          width: parent.width
          spacing: Style.space(10)

          // Recent Sessions Card
          Rectangle {
            width: parent.width
            implicitHeight: sessionsListCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: sessionsListCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  text: root.t("sessionsTitle", "󰆍 LATEST SESSIONS (1 CLI · 1 IDE)")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.t("activeWorkspaces", "Active Workspaces")
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              Repeater {
                model: (root.featuredSessions && root.featuredSessions.length > 0) ? root.featuredSessions : ((root.recentSessions && root.recentSessions.length > 0) ? root.recentSessions.slice(0, 2) : [])

                Rectangle {
                  width: parent.width
                  height: 44
                  radius: 6
                  color: sessionMouse.containsMouse ? root.cardHover : (modelData.isActive ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.08) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03))
                  border.width: 0

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(4)
                    spacing: Style.space(4)

                    // Type Icon Badge (GPU Pink #f472b6 for IDE, CPU Cyan #61d5f8 for CLI)
                    Rectangle {
                      width: 32
                      height: 32
                      radius: 5
                      color: modelData.type === "ide" ? Qt.rgba(244/255, 114/255, 182/255, 0.2) : Qt.rgba(97/255, 213/255, 248/255, 0.2)
                      border.width: 0

                      Column {
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                          anchors.horizontalCenter: parent.horizontalCenter
                          text: modelData.type === "ide" ? "󰨞" : "󰆍"
                          color: modelData.type === "ide" ? root.gpuColor : root.cpuColor
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption + 1
                        }
                        Text {
                          anchors.horizontalCenter: parent.horizontalCenter
                          text: modelData.type === "ide" ? "IDE" : "CLI"
                          color: modelData.type === "ide" ? root.gpuColor : root.cpuColor
                          font.family: root.fontFamily
                          font.pixelSize: 8
                          font.bold: true
                        }
                      }
                    }

                    // Session Details
                    Column {
                      Layout.fillWidth: true
                      spacing: 2

                      Text {
                        text: modelData.title || modelData.preview || (modelData.workspace ? String(modelData.workspace).replace(/^\/home\/[^\/]+/, "~") : "Session")
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                      }

                      Text {
                        text: (modelData.isActive ? "● Active" : "Finished") + (modelData.timeAgo ? (" · " + modelData.timeAgo) : "") + (modelData.promptCount > 0 ? (" · " + modelData.promptCount + " msg") : "") + (modelData.workspaceName ? (" · " + modelData.workspaceName) : "")
                        color: modelData.isActive ? root.primaryAccent : root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                        width: parent.width
                      }
                    }

                    // Copy Summary Button (v1.2)
                    Rectangle {
                      id: copyBtnBox
                      property bool copied: false
                      width: copyBtnText.implicitWidth + 12
                      height: 24
                      radius: 4
                      color: copyBtnBox.copied ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.20) : (copyBtnMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06))
                      border.width: 0
                      scale: copyBtnMouse.pressed ? 0.90 : 1.0

                      Behavior on scale { NumberAnimation { duration: 90 } }
                      Behavior on border.color { ColorAnimation { duration: 150 } }

                      Text {
                        id: copyBtnText
                        anchors.centerIn: parent
                        text: copyBtnBox.copied ? root.t("copied", "Copied!") : root.t("copy", "📋 Copy")
                        color: copyBtnBox.copied ? root.uploadColor : root.downloadColor
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }

                      MouseArea {
                        id: copyBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          root.copySessionSummary(modelData)
                          copyBtnBox.copied = true
                          copyResetTimer.restart()
                        }
                      }

                      Timer {
                        id: copyResetTimer
                        interval: 1400
                        onTriggered: copyBtnBox.copied = false
                      }
                    }

                    // Launch Action Button
                    Rectangle {
                      width: launchText.implicitWidth + 14
                      height: 24
                      radius: 4
                      color: launchMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                      border.width: 0
                      scale: launchMouse.pressed ? 0.90 : 1.0

                      Behavior on scale { NumberAnimation { duration: 90 } }
                      Behavior on border.color { ColorAnimation { duration: 150 } }

                      Text {
                        id: launchText
                        anchors.centerIn: parent
                        text: root.t("open", "Open")
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                      }

                      MouseArea {
                        id: launchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchSession(modelData)
                      }
                    }
                  }

                  MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchSession(modelData)
                  }
                }
              }
            }
          }

          // Card 2: 🤖 Specialized Subagents Fleet
          Rectangle {
            width: parent.width
            implicitHeight: subFleetCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: subFleetCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  text: root.t("subagentsFleetTitle", "🤖 SPECIALIZED SUBAGENTS FLEET")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.t("agentsCount", "4 Agents")
                  color: root.gpuColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // 2x2 Subagents Grid
              Grid {
                columns: 2
                width: parent.width
                spacing: Style.space(3)

                Repeater {
                  model: root.subagentsFleet && root.subagentsFleet.length > 0 ? root.subagentsFleet : [
                    { id: "sec-auditor", name: "Security Auditor", role: "AGENTS.md & 0700/0600", icon: "󰒃", status: "Ready" },
                    { id: "qml-designer-reviewer", name: "QML UI Reviewer", role: "Quickshell & Design", icon: "󰢮", status: "Ready" },
                    { id: "test-runner", name: "Test & Regression", role: "Snapshots & Sync", icon: "󰙨", status: "Ready" },
                    { id: "doc-researcher", name: "Doc & API Explorer", role: "Deep Specs & Repos", icon: "󰈙", status: "Ready" }
                  ]

                  Rectangle {
                    readonly property bool isSubWorking: modelData.status === "Working" || modelData.status === "Active"
                    readonly property bool isSubOnline: root.ready && (modelData.status !== "Offline")
                    width: (parent.width - Style.space(3)) / 2
                    height: 42
                    radius: 6
                    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                    border.width: 0

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: Style.space(3)
                      spacing: Style.space(3)

                      Rectangle {
                        width: 26
                        height: 26
                        radius: 4
                        color: Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.12)
                        border.width: 0

                        Text {
                          anchors.centerIn: parent
                          text: modelData.icon || "󰒃"
                          color: root.primaryAccent
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.bodySmall
                        }
                      }

                      Column {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                          text: modelData.name
                          color: root.foreground
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                          elide: Text.ElideRight
                          width: parent.width
                        }
                        Text {
                          text: modelData.role
                          color: root.dim
                          font.family: root.fontFamily
                          font.pixelSize: 8
                          elide: Text.ElideRight
                          width: parent.width
                        }
                      }

                      // Status Dot (Green = Online, Red = Offline)
                      Item {
                        width: 14
                        height: 14
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                          anchors.centerIn: parent
                          width: 8
                          height: 8
                          radius: 4
                          color: isSubOnline ? root.uploadColor : root.criticalColor


                          SequentialAnimation on scale {
                            running: isSubWorking && root.popupOpen
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.35; duration: 500; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // Card 3: 🖥️ Local GPU Workers (RTX 3070 CUDA)
          Rectangle {
            width: parent.width
            implicitHeight: localGpuCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: localGpuCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  text: root.t("localGpuTitle", "🖥️ LOCAL GPU WORKERS (RTX 3070)")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
              }

              // Models & VRAM Row
              RowLayout {
                width: parent.width
                spacing: Style.space(3)

                // 2 GPU Models Grid (Identical structure to Subagents Fleet)
                Grid {
                  columns: 2
                  Layout.fillWidth: true
                  spacing: Style.space(3)

                  Repeater {
                    model: [
                      {
                        name: "arci-coder",
                        id: "arci-coder",
                        fallback: "qwen2.5-coder:7b",
                        modelName: "qwen2.5-coder:7b",
                        desc: "qwen2.5-coder:7b",
                        icon: "󰘦",
                        isWorking: (root.localAiInfo && (root.localAiInfo.coderWorking || root.localAiInfo.qwenWorking)) || false
                      },
                      {
                        name: "arci-auditor",
                        id: "arci-auditor",
                        fallback: "deepseek-r1:7b",
                        modelName: "deepseek-r1:7b",
                        desc: "deepseek-r1:7b",
                        icon: "󰚩",
                        isWorking: (root.localAiInfo && (root.localAiInfo.auditorWorking || root.localAiInfo.deepseekWorking)) || false
                      }
                    ]

                    Rectangle {
                      readonly property bool isModelWorking: modelData.isWorking
                      readonly property bool isModelOnline: {
                        if (!root.localAiInfo || root.localAiInfo.status !== "Online" || !root.localAiInfo.models) return false
                        var list = root.localAiInfo.models
                        var targets = [modelData.name, modelData.id, modelData.fallback, modelData.name + ":latest"]
                        for (var i = 0; i < list.length; i++) {
                          var m = list[i]
                          for (var j = 0; j < targets.length; j++) {
                            var t = targets[j]
                            if (t && (m === t || m.startsWith(t + ":") || t.startsWith(m.split(":")[0]))) {
                              return true
                            }
                          }
                        }
                        return false
                      }
                      width: (parent.width - Style.space(3)) / 2
                      height: 42
                      radius: 6
                      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                      border.width: 0

                      RowLayout {
                        anchors.fill: parent
                        anchors.margins: Style.space(3)
                        spacing: Style.space(3)

                        Rectangle {
                          width: 26
                          height: 26
                          radius: 4
                          color: Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.12)
                          border.width: 0

                          Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: root.primaryAccent
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.bodySmall
                          }
                        }

                        Column {
                          Layout.fillWidth: true
                          spacing: 1

                          Text {
                            text: modelData.name
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                          }

                          Text {
                            text: modelData.desc
                            color: root.dim
                            font.family: root.fontFamily
                            font.pixelSize: 8
                            elide: Text.ElideRight
                            width: parent.width
                          }
                        }

                        // Status Dot (Green = Online, Red = Offline)
                        Item {
                          width: 14
                          height: 14
                          Layout.alignment: Qt.AlignVCenter

                          Rectangle {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            radius: 4
                            color: isModelOnline ? root.uploadColor : root.criticalColor


                            SequentialAnimation on scale {
                              running: isModelWorking && root.popupOpen
                              loops: Animation.Infinite
                              NumberAnimation { to: 1.35; duration: 500; easing.type: Easing.InOutQuad }
                              NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // VRAM Badge (110x42)
                Rectangle {
                  width: 110
                  height: 42
                  radius: 6
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.width: 0

                  Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: (root.localAiInfo && root.localAiInfo.vramAllocated) ? root.localAiInfo.vramAllocated : "4.7 GB / 8 GB"
                      color: root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: root.t("vramTitle", "RTX 3070 VRAM")
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                    }
                  }
                }
              }
            }
          }

          // Card 4: ⏱️ Subagents Benchmark & Latency Profiler (from Anti/Gem S)
          Rectangle {
            width: parent.width
            implicitHeight: profilerCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            readonly property var profilerList: (root.subagentProfiler && root.subagentProfiler.length > 0)
              ? root.subagentProfiler
              : [
                  { id: "sec-auditor", name: "Security Auditor", role: "AGENTS.md & 0700/0600", icon: "󰒃", runs: 22, avgLatency: "1.4s", speedScore: 98, tokensSaved: "~160k", color: "#10b981" },
                  { id: "qml-designer-reviewer", name: "QML UI Reviewer", role: "Quickshell & Design", icon: "󰚩", runs: 18, avgLatency: "0.9s", speedScore: 99, tokensSaved: "~95k", color: "#06b6d4" },
                  { id: "test-runner", name: "Test & Regression", role: "Snapshots & Sync", icon: "󰘦", runs: 16, avgLatency: "1.8s", speedScore: 95, tokensSaved: "~120k", color: "#f59e0b" },
                  { id: "doc-researcher", name: "Doc & API Explorer", role: "Deep Specs & Repos", icon: "󰋽", runs: 19, avgLatency: "2.1s", speedScore: 93, tokensSaved: "~210k", color: "#a855f7" }
                ]

            Column {
              id: profilerCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  text: root.t("subagentsBenchmarkTitle", "⏱️ SUBAGENTS BENCHMARK & LATENCY")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.t("benchmarkMode", "Deterministic Metrics")
                  color: root.primaryAccent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              Repeater {
                model: parent.parent.profilerList

                Column {
                  width: profilerCol.width
                  spacing: 2

                  RowLayout {
                    width: parent.width
                    spacing: 6

                    Text {
                      text: modelData.icon || "󰒃"
                      color: modelData.color || root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }

                    Text {
                      text: modelData.name
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }

                    Text {
                      text: "· " + (modelData.runs || 0) + " runs"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                    }

                    Item { Layout.fillWidth: true }

                    // Latency Badge
                    Rectangle {
                      height: 16
                      radius: 3
                      implicitWidth: latText.implicitWidth + 8
                      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                      border.width: 0

                      Text {
                        id: latText
                        anchors.centerIn: parent
                        text: "⚡ " + (modelData.avgLatency || "1.2s")
                        color: root.resolveSegmentColor(modelData, root.primaryAccent)
                        font.family: root.fontFamily
                        font.pixelSize: 8
                        font.bold: true
                      }
                    }

                    Text {
                      text: (modelData.tokensSaved || "~100k") + " saved"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                    }
                  }

                  // Speed score progress bar
                  Rectangle {
                    width: parent.width
                    height: 3
                    radius: 1.5
                    color: root.barTrack
                    Rectangle {
                      width: parent.width * (Number(modelData.speedScore || 95) / 100.0)
                      height: parent.height
                      radius: 1.5
                      color: root.resolveSegmentColor(modelData, root.primaryAccent)
                    }
                  }
                }
              }
            }
          }

          // Card 5: Tools Distribution Breakdown (Stacked Multi-Segment Bar & Flow Legend)
          Rectangle {
            width: parent.width
            implicitHeight: toolsListCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: toolsListCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  Layout.fillWidth: true
                  text: root.t("toolsTitle", "🛠️ TOOL CALLS BREAKDOWN")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  text: root.t("total", "Total") + ": " + root.totalToolCalls + " " + root.t("totalCalls", "calls") + " (" + (root.toolsList ? root.toolsList.length : 0) + " types)"
                  color: root.primaryAccent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // Multi-segment Stacked Horizontal Bar
              Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: root.barTrack
                clip: true

                Row {
                  anchors.fill: parent
                  spacing: 1

                  Repeater {
                    model: root.topToolsList

                    Rectangle {
                      height: parent.height
                      width: Math.max(Number(modelData.count || 0) > 0 ? 3 : 0, (parent.width * (Number(modelData.count || 0) / Math.max(1, root.totalToolCalls))))
                      color: (root.sliceColors && root.sliceColors.length > 0) ? root.sliceColors[index % root.sliceColors.length] : root.primaryAccent
                    }
                  }
                }
              }

              // Tools Segments Legend Grid
              Flow {
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: root.topToolsList

                  Row {
                    spacing: 4
                    Rectangle {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 8
                      height: 8
                      radius: 2
                      color: (root.sliceColors && root.sliceColors.length > 0) ? root.sliceColors[index % root.sliceColors.length] : root.primaryAccent
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.name + " (" + modelData.count + " · " + Math.round((Number(modelData.count || 0) / Math.max(1, root.totalToolCalls)) * 100) + "%)"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: 8
                    }
                  }
                }
              }

              // Bottom Tool Summary Badges Row
              RowLayout {
                width: parent.width
                spacing: Style.space(4)

                Rectangle {
                  Layout.fillWidth: true
                  height: 32
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.width: 0

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(3)
                    spacing: Style.space(3)

                    Text {
                      text: "Top Tool:"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                    Text {
                      text: (root.toolsList && root.toolsList.length > 0) ? (root.toolsList[0].name + " (" + root.toolsList[0].count + ")") : "—"
                      color: root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  height: 32
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.width: 0

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(3)
                    spacing: Style.space(3)

                    Text {
                      text: "Unique Tools:"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                    Text {
                      text: String(root.toolsList ? root.toolsList.length : 0) + " types"
                      color: root.uploadColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }
                }
              }
            }
          }
        }

        // 5. TAB 2: Settings
        Column {
          visible: root.selectedTab === 2
          width: parent.width
          spacing: Style.space(10)

          // Card 1: ⏱️ Telemetry & Auto-Refresh Engine
          Rectangle {
            width: parent.width
            implicitHeight: refreshCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: refreshCardCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              // Header Row (Title on left, Interval Pill centered in total width)
              Item {
                width: parent.width
                implicitHeight: 22

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.t("telemetryTitle", "⏱️ TELEMETRY & AUTO-REFRESH")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  height: 20
                  width: curIntText.implicitWidth + 14
                  radius: 4
                  color: Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.12)
                  border.color: root.primaryAccent
                  border.width: 1

                  Text {
                    id: curIntText
                    anchors.centerIn: parent
                    text: root.refreshIntervalSec + "s interval"
                    color: root.primaryAccent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }
              }

              Text {
                text: "Controls background scanning frequency for sessions, active tools, and Google AI quota resets."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                width: parent.width
                wrapMode: Text.WordWrap
              }

              // Quick Presets
              Row {
                spacing: Style.space(4)

                Repeater {
                  model: [10, 30, 60, 120, 300]

                  Rectangle {
                    height: 26
                    width: presetText.implicitWidth + 16
                    radius: 4
                    scale: presetMouse.pressed ? 0.92 : 1.0
                    color: (root.refreshIntervalSec === modelData) ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.18) : (presetMouse.containsMouse ? root.cardHover : root.cardFill)
                    border.color: (root.refreshIntervalSec === modelData) ? root.primaryAccent : root.cardBorder
                    border.width: 1

                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                      id: presetText
                      anchors.centerIn: parent
                      text: modelData + "s"
                      color: (root.refreshIntervalSec === modelData) ? root.primaryAccent : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: root.refreshIntervalSec === modelData
                    }

                    MouseArea {
                      id: presetMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.setRefreshInterval(modelData)
                    }
                  }
                }
              }
            }
          }

          // Card 2: 💓 Working Heartbeat Pulse
          Rectangle {
            width: parent.width
            implicitHeight: pulseCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: pulseCardCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width

                Row {
                  spacing: Style.space(4)
                  Layout.alignment: Qt.AlignVCenter

                  Text {
                    text: root.t("heartbeatTitle", "💓 WORKING HEARTBEAT ANIMATION")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    text: root.pulseEnabled ? ("(" + root.t("active", "Active") + ")") : ("(" + root.t("disabled", "Disabled") + ")")
                    color: root.pulseEnabled ? root.uploadColor : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Item { Layout.fillWidth: true }

                // Jumper Toggle Switch
                Rectangle {
                  id: pulseJumper
                  width: 28
                  height: 16
                  radius: 8
                  color: root.pulseEnabled ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.35) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
                  border.color: root.pulseEnabled ? root.uploadColor : root.cardBorder
                  border.width: 1

                  Behavior on color { ColorAnimation { duration: 160 } }

                  // Jumper Knob
                  Rectangle {
                    id: jumperKnob
                    width: 12
                    height: 12
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.pulseEnabled ? (parent.width - width - 2) : 2
                    color: root.pulseEnabled ? root.uploadColor : root.foreground

                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setPulseEnabled(!root.pulseEnabled)
                  }
                }
              }

              Text {
                text: "Animates the tray icon and hero logo with an anatomical heartbeat rhythm during active agent code processing."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                width: parent.width
                wrapMode: Text.WordWrap
              }

              // Pulse BPM Controls
              Column {
                width: parent.width
                spacing: Style.space(3)
                visible: root.pulseEnabled

                RowLayout {
                  width: parent.width
                  Text {
                    text: root.t("pulseCadence", "🎚️ Pulse Cadence:")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: root.pulseBpm + " BPM (" + (Math.round(60000 / root.pulseBpm) / 1000).toFixed(1) + " s/beat)"
                    color: root.primaryAccent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }
                }

                // Quick BPM Presets
                Row {
                  spacing: Style.space(4)

                  Repeater {
                    model: [
                      { name: "Sleep", bpm: 40 },
                      { name: "Rest", bpm: 60 },
                      { name: "Walk", bpm: 85 },
                      { name: "Sprint", bpm: 130 }
                    ]

                    Rectangle {
                      height: 26
                      width: bpmPresetText.implicitWidth + 16
                      radius: 4
                      scale: bpmPresetMouse.pressed ? 0.92 : 1.0
                      color: (root.pulseBpm === modelData.bpm) ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.18) : (bpmPresetMouse.containsMouse ? root.cardHover : root.cardFill)
                      border.color: (root.pulseBpm === modelData.bpm) ? root.primaryAccent : root.cardBorder
                      border.width: 1

                      Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                      Behavior on border.color { ColorAnimation { duration: 150 } }
                      Behavior on color { ColorAnimation { duration: 150 } }

                      Text {
                        id: bpmPresetText
                        anchors.centerIn: parent
                        text: modelData.name + " (" + modelData.bpm + ")"
                        color: (root.pulseBpm === modelData.bpm) ? root.primaryAccent : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                        font.bold: root.pulseBpm === modelData.bpm
                      }

                      MouseArea {
                        id: bpmPresetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setPulseBpm(modelData.bpm)
                      }
                    }
                  }
                }
              }
            }
          }

          // Card 3: 🔔 Task Completion Desktop Notifications (v1.2)
          Rectangle {
            width: parent.width
            implicitHeight: notifCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: notifCardCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width

                Row {
                  spacing: Style.space(4)
                  Layout.alignment: Qt.AlignVCenter

                  Text {
                    text: root.t("notifTitle", "🔔 TASK COMPLETION NOTIFICATIONS")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    text: root.notificationsEnabled ? ("(" + root.t("enabled", "Enabled") + ")") : ("(" + root.t("muted", "Muted") + ")")
                    color: root.notificationsEnabled ? root.uploadColor : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Item { Layout.fillWidth: true }

                // Notification Jumper Switch
                Rectangle {
                  id: notifJumper
                  width: 28
                  height: 16
                  radius: 8
                  color: root.notificationsEnabled ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.35) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
                  border.color: root.notificationsEnabled ? root.uploadColor : root.cardBorder
                  border.width: 1

                  Behavior on color { ColorAnimation { duration: 160 } }

                  Rectangle {
                    id: notifKnob
                    width: 12
                    height: 12
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.notificationsEnabled ? (parent.width - width - 2) : 2
                    color: root.notificationsEnabled ? root.uploadColor : root.foreground

                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setNotificationsEnabled(!root.notificationsEnabled)
                  }
                }
              }

              Text {
                text: root.t("notifDesc", "Sends a discreet desktop notification via notify-send whenever an autonomous coding turn or background task finishes.")
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                width: parent.width
                wrapMode: Text.WordWrap
              }
            }
          }

          // Omarchy ASCII Logo Banner (153x50 / Canvas 153x36, interactive with lightning discharge)
          Item {
            id: omarchyLogoBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 153
            height: 50
            clip: true
            scale: omarchyMouse.pressed ? 0.96 : (omarchyMouse.containsMouse ? 1.03 : 1.0)

            Behavior on scale { NumberAnimation { duration: 90 } }

            property bool animating: false
            property real elapsedFrames: 0.0
            property var heatMap: []
            property var sparks: []
            property var embers: []
            property var currentBolt: null
            property var pendingCells: []
            property real lastLaserX: 0.0
            property real lastLaserY: 25.0

            readonly property var allPalettes: [
              // 0: Omarchy Classic (Cyan -> Blue -> Purple)
              ["#ffffff", "#ffffff", "#e0f7fa", "#67e8f9", "#38bdf8", "#06b6d4", "#0284c7", "#2563eb", "#6366f1", "#8b5cf6"],
              // 1: Cyberpunk Neon (Pink -> Rose -> Magenta -> Deep Violet)
              ["#ffffff", "#ffe4e6", "#fecdd3", "#fda4af", "#fb7185", "#f43f5e", "#e11d48", "#be123c", "#a21caf", "#701a75"],
              // 2: Matrix Hacker (Ice Lime -> Emerald -> Forest Green)
              ["#ffffff", "#f0fdf4", "#dcfce7", "#bbf7d0", "#86efac", "#4ade80", "#22c55e", "#16a34a", "#15803d", "#166534"],
              // 3: Solar Synthwave (White -> Yellow -> Bright Amber -> Fiery Crimson)
              ["#ffffff", "#fefce8", "#fef08a", "#fde047", "#facc15", "#eab308", "#f97316", "#ea580c", "#dc2626", "#991b1b"],
              // 4: Nord Glacier (White -> Glacial Aqua -> Deep Arctic Teal)
              ["#ffffff", "#f0fdfa", "#ccfbf1", "#99f6e4", "#5eead4", "#2dd4bf", "#14b8a6", "#0d9488", "#0f766e", "#115e59"],
              // 5: Vaporwave Sunset (Peach -> Fuchsia -> Purple -> Midnight Indigo)
              ["#ffffff", "#fff1f2", "#fed7aa", "#fdba74", "#fb923c", "#f43f5e", "#d946ef", "#a855f7", "#7c3aed", "#4338ca"],
              // 6: Toxic Gold (White -> Electric Lime -> Golden Amber -> Bronze)
              ["#ffffff", "#f7fee7", "#ecfccb", "#d9f99d", "#bef264", "#a3e635", "#ca8a04", "#d97706", "#b45309", "#78350f"],
              // 7: Electric Amethyst (White -> Lilac -> Lavender -> Deep Velvet Purple)
              ["#ffffff", "#faf5ff", "#f3e8ff", "#e9d5ff", "#d8b4fe", "#c084fc", "#a855f7", "#9333ea", "#7e22ce", "#581c87"],
              // 8: Deep Ocean Abyss (Ice Blue -> Sky -> Azure -> Ultramarine)
              ["#ffffff", "#f0f9ff", "#e0f2fe", "#bae6fd", "#7dd3fc", "#38bdf8", "#0284c7", "#0369a1", "#1d4ed8", "#1e3a8a"]
            ]
            property int paletteIndex: 0
            property var activeGradient: allPalettes[0]

            function randomizePalette() {
              var newIdx = Math.floor(Math.random() * omarchyLogoBox.allPalettes.length)
              if (newIdx === omarchyLogoBox.paletteIndex) {
                newIdx = (omarchyLogoBox.paletteIndex + 1) % omarchyLogoBox.allPalettes.length
              }
              omarchyLogoBox.paletteIndex = newIdx
              omarchyLogoBox.activeGradient = omarchyLogoBox.allPalettes[newIdx]
            }

            function createLightningBolt(x1, y1, x2, y2) {
              var dx = x2 - x1
              var dy = y2 - y1
              var dist = Math.sqrt(dx * dx + dy * dy)
              if (dist < 1) dist = 1
              var nx = -dy / dist
              var ny = dx / dist

              var steps = 6
              var pts = [{ x: x1, y: y1 }]
              var branches = []

              for (var i = 1; i < steps; i++) {
                var t = i / steps
                var bx = x1 + dx * t
                var by = y1 + dy * t
                var maxJitter = Math.min(22, Math.max(8, dist * 0.22))
                var jitter = (Math.random() - 0.5) * 2 * maxJitter
                var px = bx + nx * jitter
                var py = by + ny * jitter
                pts.push({ x: px, y: py })

                // 1-2 fractal side branches
                if (i === 2 || i === 4) {
                  if (Math.random() > 0.35) {
                    var bPts = [{ x: px, y: py }]
                    var bLen = 10 + Math.random() * 14
                    var bJitter = jitter * 1.5 + (Math.random() - 0.5) * 10
                    var bpx = px + nx * bJitter + (dx / dist) * (bLen * 0.5)
                    var bpy = py + ny * bJitter + (dy / dist) * (bLen * 0.5)
                    bPts.push({ x: bpx, y: bpy })
                    branches.push(bPts)
                  }
                }
              }
              pts.push({ x: x2, y: y2 })

              return {
                pts: pts,
                branches: branches,
                targetX: x2,
                targetY: y2,
                life: 1.0
              }
            }

            function startLightningDischarge() {
              omarchyLogoBox.randomizePalette()
              omarchyLogoBox.heatMap = []
              omarchyLogoBox.sparks = []
              omarchyLogoBox.embers = []
              omarchyLogoBox.currentBolt = null
              omarchyLogoBox.pendingCells = []
              omarchyLogoBox.elapsedFrames = 0.0
              omarchyLogoBox.lastLaserX = Math.random() * omarchyCanvas.width
              omarchyLogoBox.lastLaserY = Math.random() * omarchyCanvas.height

              for (var r = 0; r < 10; r++) {
                var row = []
                var line = omarchyCanvas.asciiArt[r]
                for (var c = 0; c < 85; c++) {
                  row.push(0.0)
                  var ch = line.charAt(c)
                  if (ch !== " " && ch !== "") {
                    omarchyLogoBox.pendingCells.push({ r: r, c: c })
                  }
                }
                omarchyLogoBox.heatMap.push(row)
              }

              for (var i = omarchyLogoBox.pendingCells.length - 1; i > 0; i--) {
                var j = Math.floor(Math.random() * (i + 1))
                var tmp = omarchyLogoBox.pendingCells[i]
                omarchyLogoBox.pendingCells[i] = omarchyLogoBox.pendingCells[j]
                omarchyLogoBox.pendingCells[j] = tmp
              }

              omarchyLogoBox.animating = true
              omarchyLaserTimer.restart()
              omarchyCanvas.requestPaint()
            }

            Timer {
              id: omarchyLaserTimer
              interval: 16
              repeat: true
              running: omarchyLogoBox.animating && root.popupOpen
              onTriggered: {
                if (!omarchyLogoBox.animating || !root.popupOpen) return

                omarchyLogoBox.elapsedFrames += 1.0

                var cols = 85
                var rows = 10
                var cw = omarchyCanvas.width / cols
                var ch = omarchyCanvas.height / rows

                if (omarchyLogoBox.pendingCells.length > 0) {
                  var clusterSize = Math.min(omarchyLogoBox.pendingCells.length, 4)
                  var targetCell = omarchyLogoBox.pendingCells.pop()
                  omarchyLogoBox.heatMap[targetCell.r][targetCell.c] = 1.0

                  for (var cl = 1; cl < clusterSize; cl++) {
                    var extra = omarchyLogoBox.pendingCells.pop()
                    omarchyLogoBox.heatMap[extra.r][extra.c] = 1.0
                  }

                  var targetX = targetCell.c * cw + cw / 2
                  var targetY = targetCell.r * ch + ch / 2

                  omarchyLogoBox.currentBolt = omarchyLogoBox.createLightningBolt(
                    omarchyLogoBox.lastLaserX,
                    omarchyLogoBox.lastLaserY,
                    targetX,
                    targetY
                  )
                  omarchyLogoBox.lastLaserX = targetX
                  omarchyLogoBox.lastLaserY = targetY

                  for (var s = 0; s < 2; s++) {
                    omarchyLogoBox.sparks.push({
                      x: targetX + (Math.random() - 0.5) * 4,
                      y: targetY + (Math.random() - 0.5) * 4,
                      vx: (Math.random() - 0.5) * 3.5,
                      vy: (Math.random() - 0.5) * 3.5 - 1.0,
                      life: 1.0,
                      decay: 0.05 + Math.random() * 0.05,
                      size: 1.0 + Math.random() * 1.5
                    })
                  }

                  if (targetCell.r >= 8) {
                    omarchyLogoBox.embers.push({
                      x: targetX + (Math.random() - 0.5) * 6,
                      y: omarchyCanvas.height - 1,
                      vx: (Math.random() - 0.5) * 1.0,
                      vy: -Math.random() * 0.6,
                      life: 1.0,
                      decay: 0.04 + Math.random() * 0.05,
                      size: 1.0 + Math.random() * 1.5
                    })
                  }
                } else if (omarchyLogoBox.currentBolt) {
                  omarchyLogoBox.currentBolt.life -= 0.28
                  if (omarchyLogoBox.currentBolt.life <= 0) {
                    omarchyLogoBox.currentBolt = null
                  }
                }

                for (var s = omarchyLogoBox.sparks.length - 1; s >= 0; s--) {
                  var sp = omarchyLogoBox.sparks[s]
                  sp.x += sp.vx
                  sp.y += sp.vy
                  sp.vy += 0.1
                  sp.life -= sp.decay
                  if (sp.life <= 0) {
                    omarchyLogoBox.sparks.splice(s, 1)
                  }
                }

                for (var e = omarchyLogoBox.embers.length - 1; e >= 0; e--) {
                  var eb = omarchyLogoBox.embers[e]
                  eb.life -= eb.decay
                  if (eb.life <= 0) {
                    omarchyLogoBox.embers.splice(e, 1)
                  }
                }

                for (var r2 = 0; r2 < 10; r2++) {
                  for (var c2 = 0; c2 < 85; c2++) {
                    if (omarchyLogoBox.heatMap[r2] && omarchyLogoBox.heatMap[r2][c2] > 0.01) {
                      omarchyLogoBox.heatMap[r2][c2] = Math.max(0.01, omarchyLogoBox.heatMap[r2][c2] - 0.045)
                    }
                  }
                }

                omarchyCanvas.requestPaint()

                if (omarchyLogoBox.pendingCells.length === 0 && !omarchyLogoBox.currentBolt && omarchyLogoBox.sparks.length === 0 && omarchyLogoBox.embers.length === 0) {
                  omarchyLogoBox.animating = false
                  omarchyLaserTimer.stop()
                  omarchyCanvas.requestPaint()
                }
              }
            }

            Canvas {
              id: omarchyCanvas
              anchors.centerIn: parent
              width: 153
              height: 36

              readonly property var asciiArt: [
                "                 ▄▄▄                                                                 ",
                " ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄     ",
                "███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███    ",
                "███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███    ",
                "███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███    ",
                "███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███    ",
                "███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███    ",
                "███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███    ",
                " ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀     ",
                "                                       ███   █▀                                      "
              ]

              onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cols = 85
                var rows = 10
                var cw = width / cols
                var ch = height / rows
                var grad = omarchyLogoBox.activeGradient || omarchyLogoBox.allPalettes[0]

                // 1. Draw ASCII Character Blocks
                for (var r = 0; r < rows; r++) {
                  var line = asciiArt[r]

                  for (var c = 0; c < cols; c++) {
                    var heatVal = (omarchyLogoBox.heatMap[r] && omarchyLogoBox.heatMap[r][c]) || 0.0
                    if (omarchyLogoBox.animating && heatVal === 0.0) continue

                    var chChar = line.charAt(c)
                    if (chChar === " " || chChar === "") continue

                    var bx = c * cw
                    var by = r * ch

                    if (heatVal > 0.6) {
                      ctx.fillStyle = "#ffffff"
                    } else if (heatVal > 0.2) {
                      ctx.fillStyle = "#e0f7fa"
                    } else {
                      ctx.fillStyle = grad[r] || "#38bdf8"
                    }

                    if (chChar === "█") {
                      ctx.fillRect(bx, by, cw + 0.35, ch + 0.35)
                    } else if (chChar === "▄") {
                      ctx.fillRect(bx, by + ch / 2, cw + 0.35, ch / 2 + 0.35)
                    } else if (chChar === "▀") {
                      ctx.fillRect(bx, by, cw + 0.35, ch / 2 + 0.35)
                    }
                  }
                }

                // 2. Draw Floor Embers
                for (var e = 0; e < omarchyLogoBox.embers.length; e++) {
                  var eb = omarchyLogoBox.embers[e]
                  ctx.fillStyle = eb.life > 0.5 ? (grad[4] || "#38bdf8") : (grad[7] || "#8b5cf6")
                  ctx.fillRect(eb.x, eb.y, eb.size, eb.size)
                }

                // 3. Draw Electric Sparks
                for (var spIdx = 0; spIdx < omarchyLogoBox.sparks.length; spIdx++) {
                  var spk = omarchyLogoBox.sparks[spIdx]
                  ctx.fillStyle = spk.life > 0.6 ? "#ffffff" : (spk.life > 0.3 ? (grad[4] || "#38bdf8") : (grad[8] || "#a855f7"))
                  ctx.fillRect(spk.x, spk.y, spk.size, spk.size)
                }

                // 4. Draw Exactly 1 Single Fractal Lightning Bolt Discharge
                if (omarchyLogoBox.currentBolt && omarchyLogoBox.currentBolt.life > 0) {
                  var bolt = omarchyLogoBox.currentBolt
                  var bAlpha = Math.max(0.1, bolt.life)
                  var pts = bolt.pts
                  var branches = bolt.branches

                  // A. Wide Plasma Aura
                  ctx.strokeStyle = (grad[4] || "#38bdf8")
                  ctx.globalAlpha = bAlpha * 0.45
                  ctx.lineWidth = 4.8
                  ctx.beginPath()
                  ctx.moveTo(pts[0].x, pts[0].y)
                  for (var i = 1; i < pts.length; i++) {
                    ctx.lineTo(pts[i].x, pts[i].y)
                  }
                  ctx.stroke()

                  // Branches - Aura
                  for (var br = 0; br < branches.length; br++) {
                    var bp = branches[br]
                    ctx.beginPath()
                    ctx.moveTo(bp[0].x, bp[0].y)
                    ctx.lineTo(bp[1].x, bp[1].y)
                    ctx.stroke()
                  }

                  // B. Electric Mid-Arc
                  ctx.strokeStyle = (grad[7] || "#a855f7")
                  ctx.globalAlpha = bAlpha * 0.85
                  ctx.lineWidth = 2.4
                  ctx.beginPath()
                  ctx.moveTo(pts[0].x, pts[0].y)
                  for (var j = 1; j < pts.length; j++) {
                    ctx.lineTo(pts[j].x, pts[j].y)
                  }
                  ctx.stroke()

                  // Branches - Mid-Arc
                  for (var br2 = 0; br2 < branches.length; br2++) {
                    var bp2 = branches[br2]
                    ctx.beginPath()
                    ctx.moveTo(bp2[0].x, bp2[0].y)
                    ctx.lineTo(bp2[1].x, bp2[1].y)
                    ctx.stroke()
                  }
                  ctx.globalAlpha = 1.0

                  // C. White-Hot Lightning Core
                  ctx.strokeStyle = "rgba(255, 255, 255, " + bAlpha.toFixed(2) + ")"
                  ctx.lineWidth = 1.1
                  ctx.beginPath()
                  ctx.moveTo(pts[0].x, pts[0].y)
                  for (var k = 1; k < pts.length; k++) {
                    ctx.lineTo(pts[k].x, pts[k].y)
                  }
                  ctx.stroke()

                  // D. Impact Flash Corona
                  var tx = bolt.targetX
                  var ty = bolt.targetY
                  ctx.fillStyle = "rgba(255, 255, 255, " + (bAlpha * 0.9).toFixed(2) + ")"
                  ctx.fillRect(tx - 1.5, ty - 1.5, 3, 3)
                  ctx.fillStyle = "rgba(56, 189, 248, " + (bAlpha * 0.5).toFixed(2) + ")"
                  ctx.fillRect(tx - 3.5, ty - 3.5, 7, 7)
                }
              }
            }

            MouseArea {
              id: omarchyMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                omarchyLogoBox.startLightningDischarge()
              }
            }

            Component.onCompleted: {
              omarchyLogoBox.activeGradient = omarchyLogoBox.allPalettes[0]
            }
          }
        }

        // 6. Bottom Status & Manual Refresh Bar
        Rectangle {
          width: parent.width
          implicitHeight: Math.max(34, bottomStatusRow.implicitHeight + Style.space(8))
          radius: 6
          color: root.cardFill
          border.color: root.cardBorder
          border.width: 1

          RowLayout {
            id: bottomStatusRow
            anchors.fill: parent
            anchors.margins: Style.space(4)
            spacing: Style.space(4)

            Rectangle {
              width: 8
              height: 8
              radius: 4
              color: root.isWorking ? root.uploadColor : (root.isWaiting ? root.cpuColor : root.dim)
            }

            Text {
              text: root.currentModel + " · AGY " + root.serverVersion + " · " + root.secondsRemaining + "s"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              height: 24
              implicitWidth: Math.max(96, refreshBtnLayout.implicitWidth + 18)
              radius: 4
              color: refreshMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
              border.color: root.manualRefreshing ? root.primaryAccent : root.cardBorder
              border.width: 1
              scale: refreshMouse.pressed ? 0.94 : 1.0

              Behavior on scale { NumberAnimation { duration: 90 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              RowLayout {
                id: refreshBtnLayout
                anchors.centerIn: parent
                spacing: 4

                Text {
                  id: refreshIcon
                  text: "󰑐"
                  color: root.manualRefreshing ? root.primaryAccent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  transformOrigin: Item.Center
                  RotationAnimator on rotation {
                    running: root.manualRefreshing
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                  }
                }

                Text {
                  id: refreshText
                  text: root.manualRefreshing ? root.t("refreshing", "Refreshing…") : root.t("refresh", "Refresh")
                  color: root.manualRefreshing ? root.primaryAccent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: root.manualRefreshing
                }
              }

              MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.triggerManualRefresh()
              }
            }
          }
        }
      }
    }
  }
}
