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
  readonly property string appIconPath: "/home/simonez/.config/omarchy/plugins/simonez.antigem/assets/antigravity_logo.png"
  readonly property string appIconPanelPath: "/home/simonez/.config/omarchy/plugins/simonez.antigem/assets/antigravity_logo_panel.png"
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
    entry.pulseEnabled = enabled
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(entry)
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
    entry.pulseBpm = val
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(entry)
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
    entry.refreshIntervalSec = val
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(entry)
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
      Item {
        id: logoContainer
        width: 10
        height: 10
        anchors.verticalCenter: parent.verticalCenter

        Image {
          id: barAppLogo
          anchors.centerIn: parent
          width: 10
          height: 10
          source: Util.fileUrl(root.appIconPath)
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
                source: Util.fileUrl(root.appIconPanelPath)
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

            // Right Actions: Status Pill + Settings Gear Button
            Row {
              spacing: Style.space(4) + 120
              Layout.alignment: Qt.AlignVCenter

              // Status Pill (WORKING / WAITING / IDLE)
              Rectangle {
                id: statusPillRect
                height: 27
                width: statusPillText.implicitWidth + 14
                radius: 5
                color: root.isWorking ? Qt.rgba(163/255, 230/255, 53/255, 0.18) : (root.isWaiting ? Qt.rgba(97/255, 213/255, 248/255, 0.18) : root.cardFill)
                border.color: root.isWorking ? root.uploadColor : (root.isWaiting ? root.cpuColor : root.cardBorder)
                border.width: 1

                Text {
                  id: statusPillText
                  anchors.centerIn: parent
                  text: root.isWorking ? "WORKING" : (root.isWaiting ? "WAITING" : "IDLE")
                  color: root.isWorking ? root.uploadColor : (root.isWaiting ? root.cpuColor : root.dim)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  renderType: Text.NativeRendering
                }
              }

              // Header Action Button (Settings gear)
              Rectangle {
                width: 27
                height: 27
                radius: 5
                color: settingsBtnMouse.containsMouse ? root.cardHover : root.cardFill
                border.color: (root.selectedTab === 2) ? root.primaryAccent : root.cardBorder
                border.width: 1
                scale: settingsBtnMouse.pressed ? 0.92 : 1.0

                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                  anchors.centerIn: parent
                  text: "󰒓"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                }

                MouseArea {
                  id: settingsBtnMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectedTab = (root.selectedTab === 2) ? 0 : 2
                }
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
                model: (root.recentSessions && root.recentSessions.length > 0) ? root.recentSessions.slice(0, 4) : []

                Rectangle {
                  width: parent.width
                  height: 38
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
                      width: 28
                      height: 28
                      radius: 4
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
                      spacing: 1

                      Text {
                        text: modelData.title || modelData.preview || (modelData.workspace ? String(modelData.workspace).replace("/home/simonez", "~") : "Session")
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
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

          // Tools Distribution Card (Donut Pie Chart & Stats Legend)
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

                // 1. Donut Pie Chart
                Item {
                  width: 104
                  height: 104

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
                      var innerR = width / 2 - 18

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
                      font.pixelSize: Style.font.body
                      font.bold: true
                      renderType: Text.NativeRendering
                    }

                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "calls"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      renderType: Text.NativeRendering
                    }
                  }
                }

                // 2. Legend & Meter Rows
                Column {
                  Layout.fillWidth: true
                  spacing: Style.space(2)

                  Repeater {
                    model: (root.toolsList && root.toolsList.length > 0) ? root.toolsList.slice(0, 5) : []

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
                        }
                      }

                      Rectangle {
                        width: parent.width
                        height: 3
                        radius: 1.5
                        color: root.track

                        Rectangle {
                          height: parent.height
                          width: Math.min(parent.width, parent.width * (Number(modelData.count) / Math.max(1, root.totalToolCalls)))
                          radius: 1.5
                          color: toolDonutCanvas.sliceColors[index % toolDonutCanvas.sliceColors.length]
                        }
                      }
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

          Rectangle {
            width: parent.width
            implicitHeight: settingsCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: settingsCardCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(5)

              Text {
                text: "⚙️ WIDGET & PULSE SETTINGS"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }

              // 1. Refresh Interval Title
              Text {
                text: "⏱ Auto-refresh Interval"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }

              // Quick Presets
              Row {
                spacing: Style.space(4)

                Repeater {
                  model: [10, 30, 60, 120, 300]

                  Rectangle {
                    height: 26
                    width: presetText.implicitWidth + 14
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
                      font.pixelSize: Style.font.body
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

              // Custom Input
              RowLayout {
                width: parent.width
                spacing: Style.space(6)

                Text {
                  text: "Custom (s):"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }

                Rectangle {
                  height: 26
                  Layout.fillWidth: true
                  radius: 4
                  color: root.cardFill
                  border.color: customInput.activeFocus ? root.primaryAccent : root.cardBorder
                  border.width: 1

                  TextInput {
                    id: customInput
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    text: String(root.refreshIntervalSec)
                    validator: IntValidator { bottom: 5; top: 3600 }
                    selectByMouse: true

                    onAccepted: root.setRefreshInterval(text)
                  }
                }

                Rectangle {
                  id: saveIntervalBtn
                  property bool isCustomActive: !([10, 30, 60, 120, 300].includes(root.refreshIntervalSec)) || saveIntervalMouse.pressed
                  height: 26
                  width: saveText.implicitWidth + 14
                  radius: 4
                  scale: saveIntervalMouse.pressed ? 0.92 : 1.0
                  color: saveIntervalMouse.containsMouse ? root.cardHover : root.cardFill
                  border.color: isCustomActive ? root.primaryAccent : root.cardBorder
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }

                  Text {
                    id: saveText
                    anchors.centerIn: parent
                    text: "Save"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: saveIntervalBtn.isCustomActive
                  }

                  MouseArea {
                    id: saveIntervalMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setRefreshInterval(customInput.text)
                  }
                }
              }

              // Divider
              Rectangle {
                width: parent.width
                height: 1
                color: root.cardBorder
              }

              // 2. Heartbeat Pulse Jumper (OFF / ON)
              RowLayout {
                width: parent.width

                Row {
                  spacing: Style.space(6)
                  Layout.alignment: Qt.AlignVCenter

                  Text {
                    text: "💓 Working Heartbeat Pulse:"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    text: root.pulseEnabled ? "(Active)" : "(Disabled)"
                    color: root.pulseEnabled ? root.primaryAccent : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }

                Item { Layout.fillWidth: true }

                // Jumper Toggle Switch (System Monitor Electric Cyan)
                Rectangle {
                  id: pulseJumper
                  width: 26
                  height: 14
                  radius: 7
                  color: root.pulseEnabled ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.35) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
                  border.color: root.pulseEnabled ? root.primaryAccent : root.cardBorder
                  border.width: 1

                  Behavior on color { ColorAnimation { duration: 160 } }

                  // Jumper Thumb Knob
                  Rectangle {
                    id: jumperKnob
                    width: 10
                    height: 10
                    radius: 5
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

              // 3. Pulse BPM Setting (Human Heart Rate Presets)
              Column {
                width: parent.width
                spacing: Style.space(6)
                visible: root.pulseEnabled

                RowLayout {
                  width: parent.width

                  Text {
                    text: "🎚️ Pulse Speed:"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }

                  Text {
                    text: root.pulseBpm + " BPM (" + (Math.round(60000 / root.pulseBpm) / 1000).toFixed(1) + " s/beat)"
                    color: root.primaryAccent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                }

                // Quick BPM Presets (Human heart rates)
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
                      width: bpmPresetText.implicitWidth + 14
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

                // Custom BPM Input
                RowLayout {
                  width: parent.width
                  spacing: Style.space(6)

                  Text {
                    text: "Custom BPM:"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }

                  Rectangle {
                    height: 26
                    Layout.fillWidth: true
                    radius: 4
                    color: root.cardFill
                    border.color: bpmCustomInput.activeFocus ? root.primaryAccent : root.cardBorder
                    border.width: 1

                  TextInput {
                    id: bpmCustomInput
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    text: String(root.pulseBpm)
                    validator: IntValidator { bottom: 20; top: 240 }
                    selectByMouse: true

                    onAccepted: root.setPulseBpm(text)
                  }
                }

                Rectangle {
                  id: saveBpmBtn
                  property bool isCustomActive: !([40, 60, 85, 130].includes(root.pulseBpm)) || saveBpmMouse.pressed
                  height: 26
                  width: bpmSaveText.implicitWidth + 14
                  radius: 4
                  scale: saveBpmMouse.pressed ? 0.92 : 1.0
                  color: saveBpmMouse.containsMouse ? root.cardHover : root.cardFill
                  border.color: isCustomActive ? root.primaryAccent : root.cardBorder
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }

                  Text {
                    id: bpmSaveText
                    anchors.centerIn: parent
                    text: "Save"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: saveBpmBtn.isCustomActive
                  }

                  MouseArea {
                    id: saveBpmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setPulseBpm(bpmCustomInput.text)
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
