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
  property string currentModel: "Gemini 3.7 Flash"
  property int sessionGeminiPct: 0
  property string sessionGeminiDetail: "Resets in ~5h"
  property int weeklyGeminiPct: 0
  property string weeklyGeminiDetail: "Resets in ~7d"

  // Activity & Telemetry
  property int todayPrompts: 0
  property int totalPrompts: 0
  property var recentDays: []
  property var toolsList: []
  property var recentSessions: []
  property var gcpInfo: null
  property bool popupOpen: false

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

  // System Monitor palette tokens
  readonly property color cpuColor: "#61d5f8"        // Electric Cyan (CPU / 5h session / Primary Accent)
  readonly property color memoryColor: "#c7a6ff"     // Lavender Purple (Memory / 7d weekly)
  readonly property color downloadColor: "#5eead4"   // Mint Teal (Download / Activity)
  readonly property color uploadColor: "#a3e635"     // Lime Green (Upload / Working live)
  readonly property color loadColor: "#fbbf24"       // Amber Gold (Load / Prompts)
  readonly property color uptimeColor: "#94a3b8"     // Slate Gray (Uptime / Info)
  readonly property color gpuColor: "#f472b6"        // Fuchsia Pink (GPU / IDE sessions)
  readonly property color temperatureColor: "#fb923c"// Warm Orange (Temperature)
  readonly property color warningColor: "#fbbf24"    // Amber Warning
  readonly property color criticalColor: "#fb7185"   // Coral Red

  readonly property color primaryAccent: cpuColor
  readonly property color cardFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.045)
  readonly property color cardHover: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.085)
  readonly property color cardBorder: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)
  readonly property color graphGrid: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)
  readonly property color track: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.22)
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: (bar && bar.fontFamily) ? bar.fontFamily : Style.font.family

  // Tab navigation
  property int selectedTab: 0 // 0: Performance & Limits, 1: Sessions & Tools, 2: Settings

  // Python Scanner process
  property bool refreshing: false
  Process {
    id: scannerProcess
    command: ["python3", "/home/simonez/.config/omarchy/plugins/simonez.antigem/scripts/antigravity_scanner.py"]

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

      root.ready = true
      root.active = data.active === true
      root.activeStatus = String(data.activeStatus || "Idle")
      root.tierLabel = String(data.tierLabel || "Google AI Pro")
      root.currentModel = String(data.currentModel || "Gemini 3.7 Flash")
      root.todayPrompts = Number(data.todayPrompts || 0)
      root.totalPrompts = Number(data.totalPrompts || 0)
      root.recentDays = data.recentDays || []
      root.toolsList = data.tools || []
      root.recentSessions = data.recentSessions || []
      root.gcpInfo = data.gcpApis || null

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

  function requestRefresh() {
    if (root.refreshing) return
    root.refreshing = true
    root.secondsRemaining = root.refreshIntervalSec
    scannerProcess.running = true
  }

  function triggerPress(buttonCode) {
    if (buttonCode === 1) { // Left click
      root.popupOpen = !root.popupOpen
    } else if (buttonCode === 3) { // Right click
      root.selectedTab = 2
      root.popupOpen = true
    } else if (buttonCode === 2) { // Middle click
      root.requestRefresh()
    }
  }

  function open() {
    root.popupOpen = true
  }

  function close() {
    root.popupOpen = false
  }

  // Fast polling timer for live telemetry & turn completion
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      if (!root.refreshing) scannerProcess.running = true
    }
  }

  // Countdown timer for next full sync
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
    root.requestRefresh()
  }

  // Top Bar Chip Tooltip
  readonly property string barTooltip: {
    var text = "Antigravity — Google AI Pro"
    text += "\n⏱ 5h Session: " + root.sessionGeminiPct + "% (" + root.sessionGeminiDetail + ")"
    text += "\n📅 7d Weekly: " + root.weeklyGeminiPct + "% (" + root.weeklyGeminiDetail + ")"
    text += "\n🧠 Model: " + root.currentModel
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
        color: root.isWorking ? root.uploadColor : (root.sessionGeminiPct > 80 ? root.criticalColor : "#ffffff")
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        renderType: Text.NativeRendering

        SequentialAnimation {
          id: barTextHeartbeatAnim
          running: root.isWorking && root.pulseEnabled
          loops: Animation.Infinite

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
    open: root.popupOpen
    onOpenChanged: {
      if (open !== root.popupOpen) root.popupOpen = open
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
          implicitHeight: Math.max(54, headerHeroLayout.implicitHeight + Style.space(10))
          radius: 8
          color: root.cardFill
          border.color: root.cardBorder
          border.width: 1

          RowLayout {
            id: headerHeroLayout
            anchors.fill: parent
            anchors.margins: Style.space(6)
            spacing: Style.space(8)

            // App Icon Container
            Rectangle {
              width: 38
              height: 38
              radius: 6
              color: root.cardHover
              border.color: root.cardBorder
              border.width: 1

              Image {
                id: heroAppLogo
                anchors.fill: parent
                anchors.margins: 4
                source: root.appIconPanelPath
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                transformOrigin: Item.Center

                SequentialAnimation {
                  id: heroHeartbeatAnim
                  running: root.isWorking && root.pulseEnabled
                  loops: Animation.Infinite

                  NumberAnimation { target: heroAppLogo; property: "scale"; to: 1.30; duration: root.pulseT1Up; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                  NumberAnimation { target: heroAppLogo; property: "scale"; to: 1.0; duration: root.pulseT1Down; easing.type: Easing.InOutQuad }
                  NumberAnimation { target: heroAppLogo; property: "scale"; to: 1.20; duration: root.pulseT2Up; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                  NumberAnimation { target: heroAppLogo; property: "scale"; to: 1.0; duration: root.pulseT2Down; easing.type: Easing.InOutQuad }
                  PauseAnimation { duration: root.pulsePause }
                }
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

          // Status Pill (Working / Waiting / Idle) - Centered horizontally & shifted 10px up
          Rectangle {
            id: statusPillRect
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -10
            height: 20
            width: statusPillRow.implicitWidth + 14
            radius: 4
            color: root.isWorking ? Qt.rgba(163/255, 230/255, 53/255, 0.12) : (root.isWaiting ? Qt.rgba(97/255, 213/255, 248/255, 0.12) : root.cardFill)
            border.color: root.isWorking ? root.uploadColor : (root.isWaiting ? root.primaryAccent : root.cardBorder)
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
              id: statusPillRow
              anchors.centerIn: parent
              spacing: 4

              Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.isWorking ? root.uploadColor : (root.isWaiting ? root.primaryAccent : root.dim)
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                id: statusPillText
                text: root.isWorking ? "Working" : (root.isWaiting ? "Waiting" : "Idle")
                color: root.isWorking ? root.uploadColor : (root.isWaiting ? root.primaryAccent : root.foreground)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
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
              { title: "Performance", tabIndex: 0 },
              { title: "Sessions & Tools", tabIndex: 1 },
              { title: "Settings", tabIndex: 2 }
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
                onClicked: root.selectedTab = modelData.tabIndex
              }
            }
          }
        }

        // 3. TAB 0: Performance & Limits (Quotas & Sparkline)
        Column {
          visible: root.selectedTab === 0
          width: parent.width
          spacing: Style.space(10)

          // Quotas Grid (5h Session & 7d Weekly)
          RowLayout {
            width: parent.width
            spacing: Style.space(10)

            // 5h Session Card (CPU Electric Cyan #61d5f8)
            Rectangle {
              Layout.fillWidth: true
              height: 74
              radius: 8
              color: root.cardFill
              border.color: root.cardBorder
              border.width: 1

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(4)
                spacing: 2

                RowLayout {
                  width: parent.width
                  Text {
                    text: "⏱ 5H SESSION"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: root.sessionGeminiDetail
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }

                RowLayout {
                  width: parent.width
                  Text {
                    text: root.sessionGeminiPct + "%"
                    color: root.cpuColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title + 6
                    font.bold: true
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: "Usage"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                }

                // Progress Track
                Rectangle {
                  width: parent.width
                  height: 6
                  radius: 3
                  color: root.track

                  Rectangle {
                    height: parent.height
                    width: Math.min(parent.width, parent.width * (root.sessionGeminiPct / 100))
                    radius: 3
                    color: root.cpuColor
                    Behavior on width { NumberAnimation { duration: 250 } }
                  }
                }
              }
            }

            // 7d Weekly Card (Memory Lavender Purple #c7a6ff)
            Rectangle {
              Layout.fillWidth: true
              height: 74
              radius: 8
              color: root.cardFill
              border.color: root.cardBorder
              border.width: 1

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(4)
                spacing: 2

                RowLayout {
                  width: parent.width
                  Text {
                    text: "📅 7D WEEKLY"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: root.weeklyGeminiDetail
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }

                RowLayout {
                  width: parent.width
                  Text {
                    text: root.weeklyGeminiPct + "%"
                    color: root.memoryColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title + 6
                    font.bold: true
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: "Limit"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                }

                // Progress Track
                Rectangle {
                  width: parent.width
                  height: 6
                  radius: 3
                  color: root.track

                  Rectangle {
                    height: parent.height
                    width: Math.min(parent.width, parent.width * (root.weeklyGeminiPct / 100))
                    radius: 3
                    color: root.memoryColor
                    Behavior on width { NumberAnimation { duration: 250 } }
                  }
                }
              }
            }
          }

          // 7-Day Activity Bar Chart Card (System Monitor style with exact values)
          Rectangle {
            width: parent.width
            implicitHeight: promptChartCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: promptChartCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(3)

              RowLayout {
                width: parent.width
                Text {
                  text: "📊 7-DAY PROMPT ACTIVITY"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: "Today: " + root.todayPrompts + " prompts (Total: " + root.totalPrompts + ")"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              // Bar Chart Columns
              RowLayout {
                width: parent.width
                spacing: Style.space(3)

                Repeater {
                  model: root.recentDays

                  Item {
                    id: dayCol
                    Layout.fillWidth: true
                    height: 82

                    readonly property bool isToday: index === (root.recentDays.length - 1)
                    readonly property int promptVal: Number(modelData.prompts || 0)
                    readonly property real barHeightFactor: root.maxDayPrompts > 0 ? (promptVal / root.maxDayPrompts) : 0
                    readonly property bool isHovered: barMouse.containsMouse

                    Column {
                      anchors.fill: parent
                      spacing: 2

                      // 1. Exact Value on Top
                      Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: String(dayCol.promptVal)
                        color: dayCol.isToday 
                               ? root.primaryAccent 
                               : (dayCol.promptVal > 0 ? root.foreground : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35))
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: dayCol.isToday || dayCol.promptVal > 0
                        renderType: Text.NativeRendering
                      }

                      // 2. Bar Track & Filled Column
                      Rectangle {
                        width: parent.width
                        height: 48
                        radius: 3
                        color: dayCol.isHovered 
                               ? root.cardHover 
                               : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                        border.color: dayCol.isHovered ? root.cardBorder : "transparent"
                        border.width: 1

                        Rectangle {
                          anchors.bottom: parent.bottom
                          anchors.horizontalCenter: parent.horizontalCenter
                          width: parent.width
                          height: dayCol.promptVal > 0 
                                  ? Math.max(3, Math.round(dayCol.barHeightFactor * parent.height)) 
                                  : 2
                          radius: 3
                          color: dayCol.isToday 
                                 ? root.primaryAccent 
                                 : (dayCol.promptVal > 0 ? Qt.rgba(97/255, 213/255, 248/255, 0.65) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16))

                          Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                      }

                      // 3. Date Label at Bottom
                      Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                          var parts = String(modelData.date || "").split("-")
                          return parts.length === 3 ? (parts[2] + "/" + parts[1]) : ""
                        }
                        color: dayCol.isToday ? root.primaryAccent : root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: dayCol.isToday
                        renderType: Text.NativeRendering
                      }
                    }

                    MouseArea {
                      id: barMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.ArrowCursor
                    }
                  }
                }
              }
            }
          }

          // 3. GCP & Cloud APIs Availability Card
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

              // Header Row (Title on left, Online/Offline Pill centered in total width)
              Item {
                width: parent.width
                implicitHeight: 22

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: "☁️ GOOGLE CLOUD PLATFORM & APIS"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                // Online/Offline Status Pill (Centered in total width)
                Rectangle {
                  id: gcpPillBox
                  readonly property bool isOnline: (!root.gcpInfo || root.gcpInfo.status === "Online" || root.gcpInfo.status === "Operational" || (root.gcpInfo.latencyMs > 0))
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  height: 20
                  width: gcpStatusRow.implicitWidth + 14
                  radius: 4
                  color: isOnline ? Qt.rgba(163/255, 230/255, 53/255, 0.12) : Qt.rgba(251/255, 113/255, 133/255, 0.12)
                  border.color: isOnline ? root.uploadColor : root.criticalColor
                  border.width: 1

                  Row {
                    id: gcpStatusRow
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                      width: 6
                      height: 6
                      radius: 3
                      color: gcpPillBox.isOnline ? root.uploadColor : root.criticalColor
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: gcpPillBox.isOnline ? "Online" : "Offline"
                      color: gcpPillBox.isOnline ? root.uploadColor : root.criticalColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }
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
                  { name: "Gemini Language & Code API", endpoint: "generativelanguage.googleapis.com", status: "Operational", latency: "30 ms", tag: "Live Chat & Code" },
                  { name: "Vertex AI / Cloud Inference", endpoint: "aiplatform.googleapis.com", status: "Operational", latency: "33 ms", tag: "Agent Reasoning & AGY" },
                  { name: "Google Grounding & Search", endpoint: "google.com/search/api", status: "Operational", latency: "27 ms", tag: "Live Web Index" },
                  { name: "Cloud Code Sandbox Runner", endpoint: "gcp-sandbox-runner", status: "Ready", latency: "< 5 ms", tag: "Isolated Tool Execution" }
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
                      color: modelData.status === "Operational" || modelData.status === "Ready" ? root.uploadColor : root.memoryColor
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
                        text: modelData.endpoint + " · " + modelData.tag
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
                      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)

                      Text {
                        id: svcLatText
                        anchors.centerIn: parent
                        text: modelData.latency
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

              Text {
                text: "󰆍 RECENT SESSIONS (CLI & IDE)"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }

              Repeater {
                model: (root.recentSessions && root.recentSessions.length > 0) ? root.recentSessions.slice(0, 3) : []

                Rectangle {
                  width: parent.width
                  height: 42
                  radius: 6
                  color: sessionMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.color: root.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.space(4)
                    spacing: Style.space(4)

                    // Type Icon Badge (GPU Pink #f472b6 for IDE, CPU Cyan #61d5f8 for CLI)
                    Rectangle {
                      width: 30
                      height: 30
                      radius: 5
                      color: modelData.type === "ide" ? Qt.rgba(244/255, 114/255, 182/255, 0.2) : Qt.rgba(97/255, 213/255, 248/255, 0.2)
                      border.color: modelData.type === "ide" ? root.gpuColor : root.cpuColor
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: modelData.type === "ide" ? "󰨞" : "󰆍"
                        color: modelData.type === "ide" ? root.gpuColor : root.cpuColor
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                      }
                    }

                    // Session Details
                    Column {
                      Layout.fillWidth: true
                      spacing: 2

                      Text {
                        text: modelData.title || modelData.preview || (modelData.workspace ? String(modelData.workspace).replace("/home/simonez", "~") : "Session")
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

                    // Launch Action Button
                    Rectangle {
                      width: launchText.implicitWidth + 14
                      height: 24
                      radius: 4
                      color: launchMouse.containsMouse ? root.cardHover : root.cardFill
                      border.color: launchMouse.containsMouse ? root.primaryAccent : root.cardBorder
                      border.width: 1
                      scale: launchMouse.pressed ? 0.90 : 1.0

                      Behavior on scale { NumberAnimation { duration: 90 } }
                      Behavior on border.color { ColorAnimation { duration: 150 } }

                      Text {
                        id: launchText
                        anchors.centerIn: parent
                        text: "Open"
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
                        onClicked: {
                          if (root.bar && typeof root.bar.run === "function") {
                            root.bar.run("omarchy-launch-antigravity " + modelData.type + " " + modelData.id + " " + (modelData.workspace || ""))
                          }
                          root.close()
                        }
                      }
                    }
                  }

                  MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.bar && typeof root.bar.run === "function") {
                        root.bar.run("omarchy-launch-antigravity " + modelData.type + " " + modelData.id + " " + (modelData.workspace || ""))
                      }
                      root.close()
                    }
                  }
                }
              }
            }
          }

          // Tools Distribution Card (Enlarged Donut Pie Chart, Stats Legend & Summary)
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
                  text: "🛠️ TOOL CALLS BREAKDOWN"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: "Total: " + root.totalToolCalls + " calls"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              // Donut Chart & Legend Row
              RowLayout {
                width: parent.width
                spacing: Style.space(6)

                // 1. Large Donut Pie Chart
                Item {
                  width: 154
                  height: 154
                  Layout.alignment: Qt.AlignVCenter

                  Canvas {
                    id: toolDonutCanvas
                    anchors.fill: parent
                    antialiasing: true

                    readonly property var sliceColors: [
                      "#61d5f8", // Electric Cyan
                      "#5eead4", // Mint Teal
                      "#c7a6ff", // Lavender Purple
                      "#a3e635", // Lime Green
                      "#fbbf24", // Amber Gold
                      "#f472b6", // Fuchsia Pink
                      "#fb923c", // Warm Orange
                      "#94a3b8"  // Slate Gray
                    ]

                    onPaint: {
                      var ctx = getContext("2d")
                      ctx.clearRect(0, 0, width, height)

                      var tools = root.toolsList || []
                      var total = root.totalToolCalls
                      var cx = width / 2
                      var cy = height / 2
                      var outerR = width / 2 - 4
                      var innerR = width / 2 - 26

                      if (total <= 0 || tools.length === 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, outerR, 0, 2 * Math.PI, false)
                        ctx.arc(cx, cy, innerR, 2 * Math.PI, 0, true)
                        ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
                        ctx.fill()
                        return
                      }

                      var startAngle = -Math.PI / 2
                      var gapAngle = tools.length > 1 ? 0.035 : 0

                      for (var i = 0; i < tools.length; i++) {
                        var count = Number(tools[i].count || 0)
                        if (count <= 0) continue
                        var sliceAngle = (count / total) * (2 * Math.PI)
                        var endAngle = startAngle + sliceAngle - (sliceAngle > gapAngle ? gapAngle : 0)

                        ctx.beginPath()
                        ctx.arc(cx, cy, outerR, startAngle, endAngle, false)
                        ctx.arc(cx, cy, innerR, endAngle, startAngle, true)
                        ctx.closePath()

                        ctx.fillStyle = sliceColors[i % sliceColors.length]
                        ctx.fill()

                        startAngle += sliceAngle
                      }
                    }

                    Connections {
                      target: root
                      function onToolsListChanged() { toolDonutCanvas.requestPaint() }
                    }
                  }

                  // Center Total in Donut Hole
                  Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: {
                        var n = root.totalToolCalls
                        return n > 9999 ? (Math.round(n / 1000) + "k") : String(n)
                      }
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.heading
                      font.bold: true
                      renderType: Text.NativeRendering
                    }

                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "calls"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      renderType: Text.NativeRendering
                    }
                  }
                }

                // 2. Legend & Meter Rows (All Top 8 tools with spacious rows)
                Column {
                  Layout.fillWidth: true
                  spacing: Style.space(2)
                  Layout.alignment: Qt.AlignVCenter

                  Repeater {
                    model: (root.toolsList && root.toolsList.length > 0) ? root.toolsList.slice(0, 8) : []

                    Column {
                      width: parent.width
                      spacing: 2

                      RowLayout {
                        width: parent.width
                        spacing: Style.space(3)

                        Rectangle {
                          width: 8
                          height: 8
                          radius: 4
                          color: toolDonutCanvas.sliceColors[index % toolDonutCanvas.sliceColors.length]
                        }

                        Text {
                          text: modelData.name
                          color: root.foreground
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.bodySmall
                          font.bold: true
                          elide: Text.ElideRight
                          Layout.fillWidth: true
                        }

                        Text {
                          text: modelData.count + "x (" + Math.round((Number(modelData.count) / Math.max(1, root.totalToolCalls)) * 100) + "%)"
                          color: root.dim
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                        }
                      }

                      Rectangle {
                        width: parent.width
                        height: 3.5
                        radius: 1.75
                        color: root.track

                        Rectangle {
                          height: parent.height
                          width: Math.min(parent.width, parent.width * (Number(modelData.count) / Math.max(1, root.totalToolCalls)))
                          radius: 1.75
                          color: toolDonutCanvas.sliceColors[index % toolDonutCanvas.sliceColors.length]
                        }
                      }
                    }
                  }
                }
              }

              // 3. Bottom Tool Summary Badges Row
              RowLayout {
                width: parent.width
                spacing: Style.space(4)

                Rectangle {
                  Layout.fillWidth: true
                  height: 32
                  radius: 5
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.color: root.cardBorder
                  border.width: 1

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
                  border.color: root.cardBorder
                  border.width: 1

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

        // 5. TAB 2: Settings (Nastavení)
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
                  text: "⏱️ TELEMETRY & AUTO-REFRESH"
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
                    color: presetMouse.containsMouse ? root.cardHover : root.cardFill
                    border.color: (root.refreshIntervalSec === modelData) ? root.primaryAccent : root.cardBorder
                    border.width: 1

                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                      id: presetText
                      anchors.centerIn: parent
                      text: modelData + "s"
                      color: root.foreground
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
                    text: "💓 WORKING HEARTBEAT ANIMATION"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    text: root.pulseEnabled ? "(Active)" : "(Disabled)"
                    color: root.pulseEnabled ? root.primaryAccent : root.dim
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
                  color: root.pulseEnabled ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.35) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
                  border.color: root.pulseEnabled ? root.primaryAccent : root.cardBorder
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
                    color: root.pulseEnabled ? root.primaryAccent : root.foreground

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
                    text: "🎚️ Pulse Cadence:"
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
                      color: bpmPresetMouse.containsMouse ? root.cardHover : root.cardFill
                      border.color: (root.pulseBpm === modelData.bpm) ? root.primaryAccent : root.cardBorder
                      border.width: 1

                      Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                      Behavior on border.color { ColorAnimation { duration: 150 } }

                      Text {
                        id: bpmPresetText
                        anchors.centerIn: parent
                        text: modelData.name + " (" + modelData.bpm + ")"
                        color: root.foreground
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

          // Card 3: 🔧 System & Environment Integration
          Rectangle {
            width: parent.width
            implicitHeight: sysInfoCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: sysInfoCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width

                Text {
                  text: "🔧 SYSTEM & PLUGIN ENVIRONMENT"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: "v1.1 · Stable"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              // Metadata 3-col grid
              RowLayout {
                width: parent.width
                spacing: Style.space(4)

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
                      text: root.tierLabel
                      color: root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "Plan Tier"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }

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
                      text: root.currentModel
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "Active Model"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }

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
                      text: "QuickShell"
                      color: root.uploadColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "Shell Host"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }

              // Actions: Omarchy ASCII Laseretch Banner & Restart Shell
              Column {
                width: parent.width
                spacing: Style.space(3)

                // Omarchy ASCII LaserEtch Banner (Exact Video Recreation)
                // Omarchy ASCII Banner: ASCII Matrix Rain
                Rectangle {
                  id: syncBtnBox
                  width: parent.width
                  height: 68
                  radius: 6
                  clip: true
                  color: forceSyncMouse.containsMouse ? "#0a101d" : "#050811"
                  border.color: forceSyncMouse.containsMouse ? "#38bdf8" : root.cardBorder
                  border.width: 1
                  scale: forceSyncMouse.pressed ? 0.98 : 1.0

                  Behavior on scale { NumberAnimation { duration: 90 } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }

                  property bool animating: false
                  property real elapsedFrames: 0.0
                  property real totalFrames: 80.0 // Fast ~1.3s @ 60 FPS
                  property var heatMap: []
                  property var sparks: []
                  property var embers: []
                  property var laserBeams: []
                  property var pendingCells: []
                  property real lastLaserX: 0.0
                  property real lastLaserY: 25.0

                  // Exact omarchy.org Vertical Gradient (Pure White -> Cyan -> Blue -> Purple)
                  readonly property var rowGradient: [
                    "#ffffff", // Row 0: Pure White
                    "#ffffff", // Row 1: Pure White
                    "#e0f7fa", // Row 2: Ice Cyan
                    "#67e8f9", // Row 3: Light Cyan
                    "#38bdf8", // Row 4: Sky Cyan
                    "#06b6d4", // Row 5: Deep Cyan
                    "#0284c7", // Row 6: Blue
                    "#2563eb", // Row 7: Royal Blue
                    "#6366f1", // Row 8: Indigo
                    "#8b5cf6"  // Row 9: Purple
                  ]

                  function startZigZagLaser() {
                    syncBtnBox.heatMap = []
                    syncBtnBox.sparks = []
                    syncBtnBox.embers = []
                    syncBtnBox.laserBeams = []
                    syncBtnBox.pendingCells = []
                    syncBtnBox.elapsedFrames = 0.0
                    syncBtnBox.lastLaserX = Math.random() * asciiCanvas.width
                    syncBtnBox.lastLaserY = Math.random() * asciiCanvas.height

                    for (var r = 0; r < 10; r++) {
                      var row = []
                      for (var c = 0; c < 85; c++) {
                        row.push(0.0)
                        var ch = asciiCanvas.asciiArt[r].charAt(c)
                        if (ch === "█" || ch === "▄" || ch === "▀") {
                          syncBtnBox.pendingCells.push({ r: r, c: c })
                        }
                      }
                      syncBtnBox.heatMap.push(row)
                    }

                    // Randomize cell ignition order with zig-zag jumps
                    for (var i = syncBtnBox.pendingCells.length - 1; i > 0; i--) {
                      var j = Math.floor(Math.random() * (i + 1))
                      var tmp = syncBtnBox.pendingCells[i]
                      syncBtnBox.pendingCells[i] = syncBtnBox.pendingCells[j]
                      syncBtnBox.pendingCells[j] = tmp
                    }

                    syncBtnBox.animating = true
                    laserTimer.restart()
                  }

                  Timer {
                    id: laserTimer
                    interval: 16 // 60 FPS
                    repeat: true
                    running: syncBtnBox.animating

                    onTriggered: {
                      if (!syncBtnBox.animating) return

                      syncBtnBox.elapsedFrames += 1.0
                      var cw = asciiCanvas.width / 85
                      var chH = asciiCanvas.height / 10

                      // Burn multiple random zig-zag cells per frame for fast delivery (~1.3s)
                      var cellsPerFrame = Math.max(3, Math.ceil(syncBtnBox.pendingCells.length / (syncBtnBox.totalFrames * 0.75)))
                      var burnedInFrame = 0

                      while (syncBtnBox.pendingCells.length > 0 && burnedInFrame < cellsPerFrame) {
                        var cell = syncBtnBox.pendingCells.pop()
                        syncBtnBox.heatMap[cell.r][cell.c] = 1.0 // White-hot flash
                        burnedInFrame++

                        var targetX = cell.c * cw + cw / 2
                        var targetY = cell.r * chH + chH / 2

                        // Create Random Zig-Zag Laser Beam with mid-point lightning jitter
                        var midJitterX = (syncBtnBox.lastLaserX + targetX) / 2 + (Math.random() - 0.5) * 22
                        var midJitterY = (syncBtnBox.lastLaserY + targetY) / 2 + (Math.random() - 0.5) * 16

                        syncBtnBox.laserBeams.push({
                          x1: syncBtnBox.lastLaserX,
                          y1: syncBtnBox.lastLaserY,
                          mx: midJitterX,
                          my: midJitterY,
                          x2: targetX,
                          y2: targetY,
                          life: 1.0,
                          decay: 0.16 + Math.random() * 0.10
                        })

                        syncBtnBox.lastLaserX = targetX
                        syncBtnBox.lastLaserY = targetY

                        // Emit high-energy directional cutting sparks
                        for (var p = 0; p < 2; p++) {
                          syncBtnBox.sparks.push({
                            x: targetX,
                            y: targetY,
                            vx: (Math.random() - 0.5) * 3.5,
                            vy: (Math.random() - 0.6) * 3.0,
                            life: 1.0,
                            decay: 0.05 + Math.random() * 0.06,
                            size: 1 + Math.random() * 1.6
                          })
                        }

                        if (Math.random() > 0.7) {
                          syncBtnBox.embers.push({
                            x: targetX + (Math.random() - 0.5) * 6,
                            y: asciiCanvas.height - 1 - Math.random() * 2,
                            life: 1.0,
                            decay: 0.03 + Math.random() * 0.04,
                            size: 1 + Math.random() * 1.2
                          })
                        }
                      }

                      // Update zig-zag laser beams
                      for (var b = syncBtnBox.laserBeams.length - 1; b >= 0; b--) {
                        var beam = syncBtnBox.laserBeams[b]
                        beam.life -= beam.decay
                        if (beam.life <= 0) {
                          syncBtnBox.laserBeams.splice(b, 1)
                        }
                      }

                      // Update sparks
                      for (var s = syncBtnBox.sparks.length - 1; s >= 0; s--) {
                        var sp = syncBtnBox.sparks[s]
                        sp.x += sp.vx
                        sp.y += sp.vy
                        sp.vy += 0.12
                        sp.life -= sp.decay
                        if (sp.life <= 0) {
                          syncBtnBox.sparks.splice(s, 1)
                        }
                      }

                      // Update floor embers
                      for (var e = syncBtnBox.embers.length - 1; e >= 0; e--) {
                        var eb = syncBtnBox.embers[e]
                        eb.life -= eb.decay
                        if (eb.life <= 0) {
                          syncBtnBox.embers.splice(e, 1)
                        }
                      }

                      // Cool down heat map from white-hot to settled gradient
                      for (var r2 = 0; r2 < 10; r2++) {
                        for (var c2 = 0; c2 < 85; c2++) {
                          if (syncBtnBox.heatMap[r2] && syncBtnBox.heatMap[r2][c2] > 0.01) {
                            syncBtnBox.heatMap[r2][c2] = Math.max(0.01, syncBtnBox.heatMap[r2][c2] - 0.045)
                          }
                        }
                      }

                      asciiCanvas.requestPaint()

                      if (syncBtnBox.pendingCells.length === 0 && syncBtnBox.laserBeams.length === 0 && syncBtnBox.sparks.length === 0 && syncBtnBox.embers.length === 0) {
                        syncBtnBox.animating = false
                        laserTimer.stop()
                        asciiCanvas.requestPaint()
                      }
                    }
                  }

                  Canvas {
                    id: asciiCanvas
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, 336)
                    height: 50

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
                      var isHovered = forceSyncMouse.containsMouse

                      // 1. Draw ASCII Character Blocks (Random Zig-Zag Laser Etched)
                      for (var r = 0; r < rows; r++) {
                        var line = asciiArt[r]

                        for (var c = 0; c < cols; c++) {
                          var heatVal = (syncBtnBox.heatMap[r] && syncBtnBox.heatMap[r][c]) || 0.0
                          if (syncBtnBox.animating && heatVal === 0.0) continue // Hidden until laser strikes

                          var chChar = line.charAt(c)
                          if (chChar === " " || chChar === "") continue

                          var bx = c * cw
                          var by = r * ch

                          if (heatVal > 0.6) {
                            ctx.fillStyle = "#ffffff" // White-hot molten flash
                          } else if (heatVal > 0.2) {
                            ctx.fillStyle = "#e0f7fa" // Ice cyan glow
                          } else {
                            if (isHovered) {
                              ctx.fillStyle = "#67e8f9"
                            } else {
                              ctx.fillStyle = syncBtnBox.rowGradient[r] || "#38bdf8"
                            }
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
                      for (var e = 0; e < syncBtnBox.embers.length; e++) {
                        var eb = syncBtnBox.embers[e]
                        ctx.fillStyle = eb.life > 0.5 ? "#38bdf8" : "#8b5cf6"
                        ctx.fillRect(eb.x, eb.y, eb.size, eb.size)
                      }

                      // 3. Draw Laser Cutting Sparks
                      for (var spIdx = 0; spIdx < syncBtnBox.sparks.length; spIdx++) {
                        var spk = syncBtnBox.sparks[spIdx]
                        ctx.fillStyle = spk.life > 0.6 ? "#ffffff" : (spk.life > 0.3 ? "#38bdf8" : "#fde047")
                        ctx.fillRect(spk.x, spk.y, spk.size, spk.size)
                      }

                      // 4. Draw Random Zig-Zag Laser Beams (Jagged Electric Arc)
                      for (var bm = 0; bm < syncBtnBox.laserBeams.length; bm++) {
                        var bObj = syncBtnBox.laserBeams[bm]
                        var bAlpha = Math.max(0.1, bObj.life)

                        // Outer Neon Cyan Laser Glow
                        ctx.strokeStyle = "rgba(56, 189, 248, " + (bAlpha * 0.7).toFixed(2) + ")"
                        ctx.lineWidth = 3.0
                        ctx.beginPath()
                        ctx.moveTo(bObj.x1, bObj.y1)
                        ctx.lineTo(bObj.mx, bObj.my)
                        ctx.lineTo(bObj.x2, bObj.y2)
                        ctx.stroke()

                        // Core White-Hot Laser Beam
                        ctx.strokeStyle = "rgba(255, 255, 255, " + bAlpha.toFixed(2) + ")"
                        ctx.lineWidth = 1.2
                        ctx.beginPath()
                        ctx.moveTo(bObj.x1, bObj.y1)
                        ctx.lineTo(bObj.mx, bObj.my)
                        ctx.lineTo(bObj.x2, bObj.y2)
                        ctx.stroke()
                      }
                    }
                  }

                  MouseArea {
                    id: forceSyncMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      syncBtnBox.startZigZagLaser()
                      root.requestRefresh()
                    }
                  }

                  Connections {
                    target: root
                    function onRefreshingChanged() {
                      if (root.refreshing) {
                        syncBtnBox.startZigZagLaser()
                      }
                    }
                    function onSelectedTabChanged() {
                      if (root.selectedTab === 2) {
                        syncBtnBox.startZigZagLaser()
                      }
                    }
                  }

                  Component.onCompleted: {
                    syncBtnBox.startZigZagLaser()
                  }
                }

                // Restart Shell Button Row
                Rectangle {
                  width: parent.width
                  height: 32
                  radius: 5
                  color: restartShellMouse.containsMouse ? root.cardHover : root.cardFill
                  border.color: restartShellMouse.containsMouse ? root.primaryAccent : root.cardBorder
                  border.width: 1
                  scale: restartShellMouse.pressed ? 0.95 : 1.0

                  Behavior on scale { NumberAnimation { duration: 90 } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }

                  Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                      text: "󰑐"
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "Restart Omarchy Shell"
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  MouseArea {
                    id: restartShellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.bar && typeof root.bar.run === "function") {
                        root.bar.run("omarchy restart shell")
                      }
                    }
                  }
                }
              }
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
              text: root.currentModel + " · " + root.secondsRemaining + "s"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              height: 24
              width: refreshText.implicitWidth + 12
              radius: 4
              color: refreshMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
              border.color: root.cardBorder
              border.width: 1
              scale: refreshMouse.pressed ? 0.92 : 1.0

              Behavior on scale { NumberAnimation { duration: 90 } }

              Text {
                id: refreshText
                anchors.centerIn: parent
                text: root.refreshing ? "󰑐 Refreshing…" : "󰑐 Refresh"
                color: root.refreshing ? root.primaryAccent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestRefresh()
              }
            }
          }
        }
      }
    }
  }
}
