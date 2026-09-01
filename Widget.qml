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

  // Context Window & Subagents (v1.2)
  property int contextPct: 0
  property string contextTokensStr: "0k / 1M"
  property int activeSubagents: 0
  property var productivityData: ({})
  property bool notificationsEnabled: root.setting("notificationsEnabled", true) !== false
  property string currentLang: String(root.setting("language", "cs"))

  readonly property var langDictionary: ({
    "cs": {
      "tabPerf": "Výkon & Limity",
      "tabSessions": "Relace & Nástroje",
      "tabSettings": "Nastavení",
      "statusWorking": "Pracuje",
      "statusWaiting": "Čeká na vstup",
      "statusIdle": "Nečinný",
      "quota5h": "⏱ 5H RELACE",
      "quota7d": "📅 7D TÝDNÍ",
      "usage": "Využití",
      "limit": "Limit",
      "activityTitle": "📊 7-DENNÍ AKTIVITA PROMPTŮ",
      "today": "Dnes",
      "total": "Celkem",
      "prompts": "promptů",
      "contextTitle": "🧠 KONTEXT & SUBAGENTI",
      "contextMax": "Kontextové okno (1M max):",
      "subagentsActive": "Aktivní",
      "noSubagents": "Bez subagentů",
      "prodTitle": "⚡ PRODUKTIVITA & UŠETŘENÝ ČAS",
      "devTimeSaved": "Ušetřený čas",
      "toolsRun": "Nástroje",
      "tokensProcessed": "Zpracováno tokenů",
      "gcpTitle": "☁️ GOOGLE CLOUD & APIS",
      "sessionsTitle": "󰆍 POSLEDNÍ RELACE (1 CLI · 1 IDE)",
      "activeWorkspaces": "Aktivní složky",
      "copy": "📋 Kopírovat",
      "copied": "Zkopírováno!",
      "open": "Otevřít",
      "subagentsFleetTitle": "🤖 TÝM SPECIALIZOVANÝCH SUBAGENTŮ",
      "agentsCount": "4 Agenti",
      "subWorking": "Pracuje 💓",
      "subReady": "Připraven",
      "localGpuTitle": "🖥️ LOKÁLNÍ GPU WORKERS (RTX 3070)",
      "qwenDesc": "Bleskový kód & syntaxe",
      "deepseekDesc": "Logický rozbor & audit",
      "vramTitle": "RTX 3070 VRAM",
      "toolsTitle": "🛠️ ROZPAD VOLÁNÍ NÁSTROJŮ",
      "totalCalls": "volání",
      "telemetryTitle": "⏱️ TELEMETRIE & AUTO-REFRESH",
      "heartbeatTitle": "💓 SRDEČNÍ PULZ PŘI PRÁCI",
      "active": "Aktivní",
      "disabled": "Vypnuto",
      "pulseCadence": "🎚️ Rytmus pulzu:",
      "notifTitle": "🔔 DESKTOPOVÉ NOTIFIKACE ÚKOLŮ",
      "enabled": "Zapnuto",
      "muted": "Ztišeno",
      "notifDesc": "Odešle tichou systémovou notifikaci při dokončení práce agenta na pozadí.",
      "langTitle": "🌐 JAZYK & LOKALIZACE",
      "sysTitle": "🔧 SYSTÉMOVÉ PROSTŘEDÍ",
      "planTier": "Úroveň plánu",
      "activeModel": "Aktivní model",
      "refresh": "Obnovit",
      "refreshing": "Obnovuji…"
    },
    "en": {
      "tabPerf": "Performance & Limits",
      "tabSessions": "Sessions & Tools",
      "tabSettings": "Settings",
      "statusWorking": "Working",
      "statusWaiting": "Waiting",
      "statusIdle": "Idle",
      "quota5h": "⏱ 5H SESSION",
      "quota7d": "📅 7D WEEKLY",
      "usage": "Usage",
      "limit": "Limit",
      "activityTitle": "📊 7-DAY PROMPT ACTIVITY",
      "today": "Today",
      "total": "Total",
      "prompts": "prompts",
      "contextTitle": "🧠 CONTEXT & SUBAGENTS",
      "contextMax": "Context Window (1M max):",
      "subagentsActive": "Active",
      "noSubagents": "No Subagents",
      "prodTitle": "⚡ DEV PRODUCTIVITY & TIME SAVED",
      "devTimeSaved": "Dev Time Saved",
      "toolsRun": "Tools Run",
      "tokensProcessed": "Tokens Processed",
      "gcpTitle": "☁️ GOOGLE CLOUD & APIS",
      "sessionsTitle": "󰆍 LATEST SESSIONS (1 CLI · 1 IDE)",
      "activeWorkspaces": "Active Workspaces",
      "copy": "📋 Copy",
      "copied": "Copied!",
      "open": "Open",
      "subagentsFleetTitle": "🤖 SPECIALIZED SUBAGENTS FLEET",
      "agentsCount": "4 Agents",
      "subWorking": "Working 💓",
      "subReady": "Ready",
      "localGpuTitle": "🖥️ LOCAL GPU WORKERS (RTX 3070)",
      "qwenDesc": "Fast Code & Syntax",
      "deepseekDesc": "Reasoning & Audit",
      "vramTitle": "RTX 3070 VRAM",
      "toolsTitle": "🛠️ TOOL CALLS BREAKDOWN",
      "totalCalls": "calls",
      "telemetryTitle": "⏱️ TELEMETRY & AUTO-REFRESH",
      "heartbeatTitle": "💓 WORKING HEARTBEAT ANIMATION",
      "active": "Active",
      "disabled": "Disabled",
      "pulseCadence": "🎚️ Pulse Cadence:",
      "notifTitle": "🔔 TASK COMPLETION NOTIFICATIONS",
      "enabled": "Enabled",
      "muted": "Muted",
      "notifDesc": "Sends a discreet desktop notification whenever a background turn completes.",
      "langTitle": "🌐 LANGUAGE & LOCALIZATION",
      "sysTitle": "🔧 SYSTEM & PLUGIN ENVIRONMENT",
      "planTier": "Plan Tier",
      "activeModel": "Active Model",
      "refresh": "Refresh",
      "refreshing": "Refreshing…"
    },
    "it": {
      "tabPerf": "Prestazioni & Limiti",
      "tabSessions": "Sessioni & Strumenti",
      "tabSettings": "Impostazioni",
      "statusWorking": "Al lavoro",
      "statusWaiting": "In attesa",
      "statusIdle": "Inattivo",
      "quota5h": "⏱ SESSIONE 5H",
      "quota7d": "📅 SETTIMANALE 7D",
      "usage": "Utilizzo",
      "limit": "Limite",
      "activityTitle": "📊 ATTIVITÀ PROMPT 7 GIORNI",
      "today": "Oggi",
      "total": "Totale",
      "prompts": "prompt",
      "contextTitle": "🧠 CONTESTO & SUBAGENTI",
      "contextMax": "Finestra di contesto (1M max):",
      "subagentsActive": "Attivi",
      "noSubagents": "Nessun subagente",
      "prodTitle": "⚡ PRODUTTIVITÀ & TEMPO RISPARMIATO",
      "devTimeSaved": "Tempo risparmiato",
      "toolsRun": "Strumenti eseguiti",
      "tokensProcessed": "Token elaborati",
      "gcpTitle": "☁️ GOOGLE CLOUD & APIS",
      "sessionsTitle": "󰆍 ULTIME SESSIONI (1 CLI · 1 IDE)",
      "activeWorkspaces": "Workspace attivi",
      "copy": "📋 Copia",
      "copied": "Copiato!",
      "open": "Apri",
      "subagentsFleetTitle": "🤖 FLOTTA DI SUBAGENTI SPECIALIZZATI",
      "agentsCount": "4 Agenti",
      "subWorking": "Al lavoro 💓",
      "subReady": "Pronto",
      "localGpuTitle": "🖥️ WORKER GPU LOCALI (RTX 3070)",
      "qwenDesc": "Codice rapido & sintassi",
      "deepseekDesc": "Ragionamento & audit",
      "vramTitle": "VRAM RTX 3070",
      "toolsTitle": "🛠️ RIPARTIZIONE DEGLI STRUMENTI",
      "totalCalls": "chiamate",
      "telemetryTitle": "⏱️ TELEMETRIA & AUTO-REFRESH",
      "heartbeatTitle": "💓 ANIMAZIONE BATTITO CARDIACO",
      "active": "Attivo",
      "disabled": "Disattivato",
      "pulseCadence": "🎚️ Cadenza battito:",
      "notifTitle": "🔔 NOTIFICHE DI COMPLETAMENTO",
      "enabled": "Attivato",
      "muted": "Silenzioso",
      "notifDesc": "Invia una notifica discreta quando l'agente termina un'attività.",
      "langTitle": "🌐 LINGUA & LOCALIZZAZIONE",
      "sysTitle": "🔧 AMBIENTE DI SISTEMA",
      "planTier": "Piano",
      "activeModel": "Modello attivo",
      "refresh": "Aggiorna",
      "refreshing": "Aggiornamento…"
    },
    "de": {
      "tabPerf": "Leistung & Limits",
      "tabSessions": "Sitzungen & Tools",
      "tabSettings": "Einstellungen",
      "statusWorking": "Arbeitet",
      "statusWaiting": "Wartet",
      "statusIdle": "Inaktiv",
      "quota5h": "⏱ 5H SITZUNG",
      "quota7d": "📅 7T WÖCHENTLICH",
      "usage": "Nutzung",
      "limit": "Limit",
      "activityTitle": "📊 7-TAGE PROMPT-AKTIVITÄT",
      "today": "Heute",
      "total": "Gesamt",
      "prompts": "Prompts",
      "contextTitle": "🧠 KONTEXT & SUBAGENTEN",
      "contextMax": "Kontextfenster (1M max):",
      "subagentsActive": "Aktiv",
      "noSubagents": "Keine Subagenten",
      "prodTitle": "⚡ PRODUKTIVITÄT & ZEITERSPARNIS",
      "devTimeSaved": "Zeit gespart",
      "toolsRun": "Tools ausgeführt",
      "tokensProcessed": "Token verarbeitet",
      "gcpTitle": "☁️ GOOGLE CLOUD & APIS",
      "sessionsTitle": "󰆍 LETZTE SITZUNGEN (1 CLI · 1 IDE)",
      "activeWorkspaces": "Aktive Arbeitsbereiche",
      "copy": "📋 Kopieren",
      "copied": "Kopiert!",
      "open": "Öffnen",
      "subagentsFleetTitle": "🤖 SPEZIALISIERTE SUBAGENTEN-FLOTTE",
      "agentsCount": "4 Agenten",
      "subWorking": "Arbeitet 💓",
      "subReady": "Bereit",
      "localGpuTitle": "🖥️ LOKALE GPU-WORKER (RTX 3070)",
      "qwenDesc": "Schneller Code & Syntax",
      "deepseekDesc": "Logik & Sicherheitsaudit",
      "vramTitle": "RTX 3070 VRAM",
      "toolsTitle": "🛠️ WERKZEUG-AUFRUFE",
      "totalCalls": "Aufrufe",
      "telemetryTitle": "⏱️ TELEMETRIE & AUTO-REFRESH",
      "heartbeatTitle": "💓 HERZSCHLAG-ANIMATION",
      "active": "Aktiv",
      "disabled": "Deaktiviert",
      "pulseCadence": "🎚️ Pulsfrequenz:",
      "notifTitle": "🔔 BENACHRICHTIGUNGEN BEI ABSCHLUSS",
      "enabled": "Aktiviert",
      "muted": "Stumm",
      "notifDesc": "Sendet eine Benachrichtigung, wenn eine Hintergrundaufgabe abgeschlossen ist.",
      "langTitle": "🌐 SPRACHE & LOKALISIERUNG",
      "sysTitle": "🔧 SYSTEMUMGEBUNG",
      "planTier": "Tarif",
      "activeModel": "Aktives Modell",
      "refresh": "Aktualisieren",
      "refreshing": "Aktualisiere…"
    },
    "es": {
      "tabPerf": "Rendimiento",
      "tabSessions": "Sesiones & Herramientas",
      "tabSettings": "Ajustes",
      "statusWorking": "Trabajando",
      "statusWaiting": "Esperando",
      "statusIdle": "Inactivo",
      "quota5h": "⏱ SESIÓN 5H",
      "quota7d": "📅 SEMANAL 7D",
      "usage": "Uso",
      "limit": "Límite",
      "activityTitle": "📊 ACTIVIDAD DE PROMPTS (7 DÍAS)",
      "today": "Hoy",
      "total": "Total",
      "prompts": "prompts",
      "contextTitle": "🧠 CONTEXTO & SUBAGENTES",
      "contextMax": "Ventana de contexto (1M máx):",
      "subagentsActive": "Activos",
      "noSubagents": "Sin subagentes",
      "prodTitle": "⚡ PRODUCTIVIDAD & TIEMPO AHORRADO",
      "devTimeSaved": "Tiempo ahorrado",
      "toolsRun": "Herramientas",
      "tokensProcessed": "Tokens procesados",
      "gcpTitle": "☁️ GOOGLE CLOUD & APIS",
      "sessionsTitle": "󰆍 ÚLTIMAS SESIONES (1 CLI · 1 IDE)",
      "activeWorkspaces": "Espacios de trabajo",
      "copy": "📋 Copiar",
      "copied": "¡Copiado!",
      "open": "Abrir",
      "subagentsFleetTitle": "🤖 FLOTA DE SUBAGENTES ESPECIALIZADOS",
      "agentsCount": "4 Agentes",
      "subWorking": "Trabajando 💓",
      "subReady": "Listo",
      "localGpuTitle": "🖥️ TRABAJADORES GPU LOCALES (RTX 3070)",
      "qwenDesc": "Código rápido y sintaxis",
      "deepseekDesc": "Razonamiento y auditoría",
      "vramTitle": "VRAM RTX 3070",
      "toolsTitle": "🛠️ DESGLOSE DE HERRAMIENTAS",
      "totalCalls": "llamadas",
      "telemetryTitle": "⏱️ TELEMETRÍA & AUTO-REFRESH",
      "heartbeatTitle": "💓 ANIMACIÓN DE LATIDO",
      "active": "Activo",
      "disabled": "Desactivado",
      "pulseCadence": "🎚️ Cadencia del pulso:",
      "notifTitle": "🔔 NOTIFICACIONES DE TAREAS",
      "enabled": "Activado",
      "muted": "Silenciado",
      "notifDesc": "Envía una notificación de escritorio cuando termina una tarea.",
      "langTitle": "🌐 IDIOMA Y LOCALIZACIÓN",
      "sysTitle": "🔧 ENTORNO DEL SISTEMA",
      "planTier": "Plan",
      "activeModel": "Modelo activo",
      "refresh": "Actualizar",
      "refreshing": "Actualizando…"
    },
    "fr": {
      "tabPerf": "Performances",
      "tabSessions": "Sessions & Outils",
      "tabSettings": "Paramètres",
      "statusWorking": "En cours",
      "statusWaiting": "En attente",
      "statusIdle": "Inactif",
      "quota5h": "⏱ SESSION 5H",
      "quota7d": "📅 HEBDOMADAIRE 7J",
      "usage": "Utilisation",
      "limit": "Limite",
      "activityTitle": "📊 ACTIVITÉ DES PROMPTS (7 JOURS)",
      "today": "Aujourd'hui",
      "total": "Total",
      "prompts": "prompts",
      "contextTitle": "🧠 CONTEXTE & SOUS-AGENTS",
      "contextMax": "Fenêtre de contexte (1M max):",
      "subagentsActive": "Actifs",
      "noSubagents": "Aucun sous-agent",
      "prodTitle": "⚡ PRODUCTIVITÉ & TEMPS GAGNÉ",
      "devTimeSaved": "Temps gagné",
      "toolsRun": "Outils exécutés",
      "tokensProcessed": "Tokens traités",
      "gcpTitle": "☁️ GOOGLE CLOUD & APIS",
      "sessionsTitle": "󰆍 DERNIÈRES SESSIONS (1 CLI · 1 IDE)",
      "activeWorkspaces": "Espaces de travail",
      "copy": "📋 Copier",
      "copied": "Copié !",
      "open": "Ouvrir",
      "subagentsFleetTitle": "🤖 FLOTTE DE SOUS-AGENTS SPÉCIALISÉS",
      "agentsCount": "4 Agents",
      "subWorking": "En cours 💓",
      "subReady": "Prêt",
      "localGpuTitle": "🖥️ WORKERS GPU LOCAUX (RTX 3070)",
      "qwenDesc": "Code rapide & syntaxe",
      "deepseekDesc": "Raisonnement & audit",
      "vramTitle": "VRAM RTX 3070",
      "toolsTitle": "🛠️ RÉPARTITION DES OUTILS",
      "totalCalls": "appels",
      "telemetryTitle": "⏱️ TÉLÉMÉTRIE & AUTO-REFRESH",
      "heartbeatTitle": "💓 BATTEMENT DE CŒUR EN COURS",
      "active": "Actif",
      "disabled": "Désactivé",
      "pulseCadence": "🎚️ Cadence du pouls :",
      "notifTitle": "🔔 NOTIFICATIONS DE FIN DE TÂCHE",
      "enabled": "Activé",
      "muted": "Muet",
      "notifDesc": "Envoie une notification lorsqu'une tâche d'agent est terminée.",
      "langTitle": "🌐 LANGUE & LOCALISATION",
      "sysTitle": "🔧 ENVIRONNEMENT SYSTÈME",
      "planTier": "Abonnement",
      "activeModel": "Modèle actif",
      "refresh": "Actualiser",
      "refreshing": "Actualisation…"
    },
    "uk": {
      "tabPerf": "Продуктивність та ліміти",
      "tabSessions": "Сесії та інструменти",
      "tabSettings": "Налаштування",
      "statusWorking": "Працює",
      "statusWaiting": "Очікує вводу",
      "statusIdle": "У спокої",
      "quota5h": "⏱ 5-ГОД СЕСІЯ",
      "quota7d": "📅 7Д ТИЖНЕВИЙ",
      "usage": "Використання",
      "limit": "Ліміт",
      "activityTitle": "📊 7-ДЕННА АКТИВНІСТЬ ПРОМПТІВ",
      "today": "Сьогодні",
      "total": "Всього",
      "prompts": "промптів",
      "contextTitle": "🧠 КОНТЕКСТ ТА СУБАГЕНТИ",
      "contextMax": "Контекстне вікно (макс. 1M):",
      "subagentsActive": "Активні",
      "noSubagents": "Без субагентів",
      "prodTitle": "⚡ ПРОДУКТИВНІСТЬ І ЗБЕРЕЖЕНИЙ ЧАС",
      "devTimeSaved": "Збережений час",
      "toolsRun": "Інструменти",
      "tokensProcessed": "Оброблено токенів",
      "gcpTitle": "☁️ GOOGLE CLOUD І APIS",
      "sessionsTitle": "󰆍 ОСТАННІ СЕСІЇ (1 CLI · 1 IDE)",
      "activeWorkspaces": "Робочі простори",
      "copy": "📋 Копіювати",
      "copied": "Скопійовано!",
      "open": "Відкрити",
      "subagentsFleetTitle": "🤖 КОМАНДА СПЕЦІАЛІЗОВАНИХ СУБАГЕНТІВ",
      "agentsCount": "4 Агенти",
      "subWorking": "Працює 💓",
      "subReady": "Готовий",
      "localGpuTitle": "🖥️ ЛОКАЛЬНІ GPU WORKERS (RTX 3070)",
      "qwenDesc": "Швидкий код і синтаксис",
      "deepseekDesc": "Міркування та аудит",
      "vramTitle": "RTX 3070 VRAM",
      "toolsTitle": "🛠️ РОЗПОДІЛ ВИКЛИКІВ ІНСТРУМЕНТІВ",
      "totalCalls": "викликів",
      "telemetryTitle": "⏱️ ТЕЛЕМЕТРІЯ ТА АВТООНОВЛЕННЯ",
      "heartbeatTitle": "💓 СЕРЦЕБИТТЯ ПРИ РОБОТІ",
      "active": "Активно",
      "disabled": "Вимкнено",
      "pulseCadence": "🎚️ Ритм пульсу:",
      "notifTitle": "🔔 СПОВІЩЕННЯ ПРО ЗАВЕРШЕННЯ",
      "enabled": "Увімкнено",
      "muted": "Без звуку",
      "notifDesc": "Надсилає сповіщення при завершенні фонового завдання.",
      "langTitle": "🌐 МОВА ТА ЛОКАЛІЗАЦІЯ",
      "sysTitle": "🔧 СИСТЕМНЕ СЕРЕДОВИЩЕ",
      "planTier": "Рівень плану",
      "activeModel": "Активна модель",
      "refresh": "Оновити",
      "refreshing": "Оновлюю…"
    },
    "ja": {
      "tabPerf": "パフォーマンス",
      "tabSessions": "セッション＆ツール",
      "tabSettings": "設定",
      "statusWorking": "処理中",
      "statusWaiting": "入力待ち",
      "statusIdle": "アイドル",
      "quota5h": "⏱ 5時間セッション",
      "quota7d": "📅 7日間制限",
      "usage": "使用量",
      "limit": "上限",
      "activityTitle": "📊 7日間のプロンプト活動",
      "today": "本日",
      "total": "合計",
      "prompts": "プロンプト",
      "contextTitle": "🧠 コンテキスト＆エージェント",
      "contextMax": "コンテキストウィンドウ (最大 1M):",
      "subagentsActive": "稼働中",
      "noSubagents": "サブエージェントなし",
      "prodTitle": "⚡ 開発生産性＆節約時間",
      "devTimeSaved": "節約された開発時間",
      "toolsRun": "実行ツール数",
      "tokensProcessed": "処理済みトークン",
      "gcpTitle": "☁️ GOOGLE CLOUD＆API",
      "sessionsTitle": "󰆍 最新セッション (1 CLI · 1 IDE)",
      "activeWorkspaces": "ワークスペース",
      "copy": "📋 コピー",
      "copied": "コピー完了!",
      "open": "開く",
      "subagentsFleetTitle": "🤖 専門サブエージェント艦隊",
      "agentsCount": "4 エージェント",
      "subWorking": "処理中 💓",
      "subReady": "待機中",
      "localGpuTitle": "🖥️ ローカル GPU ワーカー (RTX 3070)",
      "qwenDesc": "高速コード生成＆構文",
      "deepseekDesc": "推論＆セキュリティ監査",
      "vramTitle": "RTX 3070 VRAM",
      "toolsTitle": "🛠️ ツール呼び出し内訳",
      "totalCalls": "回",
      "telemetryTitle": "⏱️ テレメトリ＆自動更新",
      "heartbeatTitle": "💓 稼働中ハートビート脈拍",
      "active": "有効",
      "disabled": "無効",
      "pulseCadence": "🎚️ 脈拍リズム:",
      "notifTitle": "🔔 タスク完了デスクトップ通知",
      "enabled": "有効",
      "muted": "ミュート",
      "notifDesc": "バックグラウンド作業完了時にデスクトップ通知を送信します。",
      "langTitle": "🌐 言語とローカライゼーション",
      "sysTitle": "🔧 システム環境",
      "planTier": "プラン",
      "activeModel": "アクティブモデル",
      "refresh": "更新",
      "refreshing": "更新中…"
    }
  })

  function t(key, fallback) {
    if (root.langDictionary && root.langDictionary[root.currentLang] && root.langDictionary[root.currentLang][key]) {
      return root.langDictionary[root.currentLang][key]
    }
    if (root.langDictionary && root.langDictionary["en"] && root.langDictionary["en"][key]) {
      return root.langDictionary["en"][key]
    }
    return fallback || key
  }

  function setLanguage(langCode) {
    root.currentLang = langCode
    var entry = { id: root.moduleName }
    if (root.settings && typeof root.settings === "object") {
      for (var key in root.settings) {
        if (key !== "id") entry[key] = root.settings[key]
      }
    }
    entry["language"] = langCode
    root.settings = entry

    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    }
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
  readonly property url omarchyIconPath: Qt.resolvedUrl("assets/omarchy.png")
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

  readonly property color primaryAccent: cpuColor
  readonly property color cardFill: Qt.rgba(accent.r, accent.g, accent.b, 0.045)
  readonly property color cardHover: Qt.rgba(accent.r, accent.g, accent.b, 0.09)
  readonly property color cardBorder: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
  readonly property color graphGrid: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
  readonly property color track: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
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
      root.currentModel = String(data.currentModel || "Gemini 3.7 Flash")
      root.todayPrompts = Number(data.todayPrompts || 0)
      root.totalPrompts = Number(data.totalPrompts || 0)
      root.recentDays = data.recentDays || []
      root.toolsList = data.tools || []
      root.recentSessions = data.recentSessions || []
      root.featuredSessions = (data.featuredSessions && data.featuredSessions.length > 0) ? data.featuredSessions : ((data.recentSessions && data.recentSessions.length > 0) ? data.recentSessions.slice(0, 2) : [])
      root.gcpInfo = data.gcpApis || null
      root.localAiInfo = data.localAi || null
      root.subagentsFleet = data.subagentsFleet || []

      root.contextPct = Number(data.contextPct || 0)
      root.contextTokensStr = String(data.contextTokensStr || "0k / 1M")
      root.activeSubagents = Number(data.activeSubagents || 0)
      root.productivityData = data.productivity || {}

      // Feature 2: Task Completion Desktop Notification
      if (root.notificationsEnabled && wasWorking && !root.isWorking && root.activeStatus !== "Working") {
        if (root.bar && typeof root.bar.run === "function") {
          root.bar.run("notify-send -a 'Antigravity' -i 'dialog-information' 'Antigravity AI' '✅ Úkol dokončen! Všechny změny a testy jsou hotové.'")
        }
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
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run("bash -c 'printf " + JSON.stringify(md) + " | wl-copy'")
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
        color: root.isWorking ? root.uploadColor : (root.sessionGeminiPct > 80 ? root.criticalColor : "#ffffff")
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
        headerOmarchyLogoBox.startLightningDischarge()
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
                transformOrigin: Item.Center

                SequentialAnimation {
                  id: heroHeartbeatAnim
                  running: root.isWorking && root.pulseEnabled && root.popupOpen
                  loops: Animation.Infinite
                  onRunningChanged: {
                    if (!running) heroAppLogo.scale = 1.0
                  }

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

            // Omarchy ASCII Logo Banner (Right side, level with Antigravity logo, exactly identical to settings logo)
            Item {
              id: headerOmarchyLogoBox
              width: 153
              height: 50
              clip: true
              scale: headerOmarchyMouse.pressed ? 0.96 : 1.0

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
                var newIdx = Math.floor(Math.random() * headerOmarchyLogoBox.allPalettes.length)
                if (newIdx === headerOmarchyLogoBox.paletteIndex) {
                  newIdx = (headerOmarchyLogoBox.paletteIndex + 1) % headerOmarchyLogoBox.allPalettes.length
                }
                headerOmarchyLogoBox.paletteIndex = newIdx
                headerOmarchyLogoBox.activeGradient = headerOmarchyLogoBox.allPalettes[newIdx]
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
                headerOmarchyLogoBox.randomizePalette()
                headerOmarchyLogoBox.heatMap = []
                headerOmarchyLogoBox.sparks = []
                headerOmarchyLogoBox.embers = []
                headerOmarchyLogoBox.currentBolt = null
                headerOmarchyLogoBox.pendingCells = []
                headerOmarchyLogoBox.elapsedFrames = 0.0
                headerOmarchyLogoBox.lastLaserX = Math.random() * headerCanvas.width
                headerOmarchyLogoBox.lastLaserY = Math.random() * headerCanvas.height

                for (var r = 0; r < 10; r++) {
                  var row = []
                  for (var c = 0; c < 85; c++) {
                    row.push(0.0)
                    var ch = headerCanvas.asciiArt[r].charAt(c)
                    if (ch === "█" || ch === "▄" || ch === "▀") {
                      headerOmarchyLogoBox.pendingCells.push({ r: r, c: c })
                    }
                  }
                  headerOmarchyLogoBox.heatMap.push(row)
                }

                for (var i = headerOmarchyLogoBox.pendingCells.length - 1; i > 0; i--) {
                  var j = Math.floor(Math.random() * (i + 1))
                  var tmp = headerOmarchyLogoBox.pendingCells[i]
                  headerOmarchyLogoBox.pendingCells[i] = headerOmarchyLogoBox.pendingCells[j]
                  headerOmarchyLogoBox.pendingCells[j] = tmp
                }

                headerOmarchyLogoBox.animating = true
                headerLaserTimer.restart()
              }

              Timer {
                id: headerLaserTimer
                interval: 16
                repeat: true
                running: headerOmarchyLogoBox.animating && root.popupOpen

                onTriggered: {
                  if (!headerOmarchyLogoBox.animating || !root.popupOpen) return

                  headerOmarchyLogoBox.elapsedFrames += 1.0
                  var cw = headerCanvas.width / 85
                  var chH = headerCanvas.height / 10

                  if (headerOmarchyLogoBox.pendingCells.length > 0) {
                    var clusterSize = Math.min(headerOmarchyLogoBox.pendingCells.length, 4)
                    var targetCell = headerOmarchyLogoBox.pendingCells.pop()
                    headerOmarchyLogoBox.heatMap[targetCell.r][targetCell.c] = 1.0

                    for (var k = 1; k < clusterSize; k++) {
                      var extra = headerOmarchyLogoBox.pendingCells.pop()
                      headerOmarchyLogoBox.heatMap[extra.r][extra.c] = 1.0
                    }

                    var targetX = targetCell.c * cw + cw / 2
                    var targetY = targetCell.r * chH + chH / 2

                    headerOmarchyLogoBox.currentBolt = headerOmarchyLogoBox.createLightningBolt(
                      headerOmarchyLogoBox.lastLaserX,
                      headerOmarchyLogoBox.lastLaserY,
                      targetX,
                      targetY
                    )

                    headerOmarchyLogoBox.lastLaserX = targetX
                    headerOmarchyLogoBox.lastLaserY = targetY

                    for (var p = 0; p < 4; p++) {
                      headerOmarchyLogoBox.sparks.push({
                        x: targetX,
                        y: targetY,
                        vx: (Math.random() - 0.5) * 6.5,
                        vy: (Math.random() - 0.6) * 5.5,
                        life: 1.0,
                        decay: 0.04 + Math.random() * 0.05,
                        size: 1.5 + Math.random() * 2.5
                      })
                    }

                    if (Math.random() > 0.60) {
                      headerOmarchyLogoBox.embers.push({
                        x: targetX + (Math.random() - 0.5) * 12,
                        y: headerCanvas.height - 1 - Math.random() * 4,
                        life: 1.0,
                        decay: 0.025 + Math.random() * 0.035,
                        size: 1.5 + Math.random() * 2.0
                      })
                    }
                  } else if (headerOmarchyLogoBox.currentBolt) {
                    headerOmarchyLogoBox.currentBolt.life -= 0.28
                    if (headerOmarchyLogoBox.currentBolt.life <= 0) {
                      headerOmarchyLogoBox.currentBolt = null
                    }
                  }

                  for (var s = headerOmarchyLogoBox.sparks.length - 1; s >= 0; s--) {
                    var sp = headerOmarchyLogoBox.sparks[s]
                    sp.x += sp.vx
                    sp.y += sp.vy
                    sp.vy += 0.16
                    sp.life -= sp.decay
                    if (sp.life <= 0) {
                      headerOmarchyLogoBox.sparks.splice(s, 1)
                    }
                  }

                  for (var e = headerOmarchyLogoBox.embers.length - 1; e >= 0; e--) {
                    var eb = headerOmarchyLogoBox.embers[e]
                    eb.life -= eb.decay
                    if (eb.life <= 0) {
                      headerOmarchyLogoBox.embers.splice(e, 1)
                    }
                  }

                  for (var r2 = 0; r2 < 10; r2++) {
                    for (var c2 = 0; c2 < 85; c2++) {
                      if (headerOmarchyLogoBox.heatMap[r2] && headerOmarchyLogoBox.heatMap[r2][c2] > 0.01) {
                        headerOmarchyLogoBox.heatMap[r2][c2] = Math.max(0.01, headerOmarchyLogoBox.heatMap[r2][c2] - 0.045)
                      }
                    }
                  }

                  headerCanvas.requestPaint()

                  if (headerOmarchyLogoBox.pendingCells.length === 0 && !headerOmarchyLogoBox.currentBolt && headerOmarchyLogoBox.sparks.length === 0 && headerOmarchyLogoBox.embers.length === 0) {
                    headerOmarchyLogoBox.animating = false
                    headerLaserTimer.stop()
                    headerCanvas.requestPaint()
                  }
                }
              }

              Canvas {
                id: headerCanvas
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
                  var grad = headerOmarchyLogoBox.activeGradient || headerOmarchyLogoBox.allPalettes[0]

                  // 1. Draw ASCII Character Blocks
                  for (var r = 0; r < rows; r++) {
                    var line = asciiArt[r]

                    for (var c = 0; c < cols; c++) {
                      var heatVal = (headerOmarchyLogoBox.heatMap[r] && headerOmarchyLogoBox.heatMap[r][c]) || 0.0
                      if (headerOmarchyLogoBox.animating && heatVal === 0.0) continue

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
                  for (var e = 0; e < headerOmarchyLogoBox.embers.length; e++) {
                    var eb = headerOmarchyLogoBox.embers[e]
                    ctx.fillStyle = eb.life > 0.5 ? (grad[4] || "#38bdf8") : (grad[7] || "#8b5cf6")
                    ctx.fillRect(eb.x, eb.y, eb.size, eb.size)
                  }

                  // 3. Draw Electric Sparks
                  for (var spIdx = 0; spIdx < headerOmarchyLogoBox.sparks.length; spIdx++) {
                    var spk = headerOmarchyLogoBox.sparks[spIdx]
                    ctx.fillStyle = spk.life > 0.6 ? "#ffffff" : (spk.life > 0.3 ? (grad[4] || "#38bdf8") : (grad[8] || "#a855f7"))
                    ctx.fillRect(spk.x, spk.y, spk.size, spk.size)
                  }

                  // 4. Draw Exactly 1 Single Fractal Lightning Bolt Discharge
                  if (headerOmarchyLogoBox.currentBolt && headerOmarchyLogoBox.currentBolt.life > 0) {
                    var bolt = headerOmarchyLogoBox.currentBolt
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
                id: headerOmarchyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  headerOmarchyLogoBox.startLightningDischarge()
                }
              }

              Connections {
                target: root
                function onPopupOpenChanged() {
                  if (!root.popupOpen && headerOmarchyLogoBox.animating) {
                    headerOmarchyLogoBox.animating = false
                    headerLaserTimer.stop()
                  }
                }
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
            color: root.isWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.12) : (root.isWaiting ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.12) : root.cardFill)
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
                text: root.isWorking ? root.t("statusWorking", "Working") : (root.isWaiting ? root.t("statusWaiting", "Waiting") : root.t("statusIdle", "Idle"))
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
                  headerOmarchyLogoBox.startLightningDischarge()
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
                    text: root.t("quota5h", "⏱ 5H SESSION")
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
                    text: root.t("usage", "Usage")
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
                    text: root.t("quota7d", "📅 7D WEEKLY")
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
                    text: root.t("limit", "Limit")
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
                  text: root.t("activityTitle", "📊 7-DAY PROMPT ACTIVITY")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.t("today", "Today") + ": " + root.todayPrompts + " " + root.t("prompts", "prompts") + " (" + root.t("total", "Total") + ": " + root.totalPrompts + ")"
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

          // 3. Active Context Window & Subagents Card (v1.2)
          Rectangle {
            width: parent.width
            implicitHeight: contextCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: contextCardCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(3)

              RowLayout {
                width: parent.width
                spacing: Style.space(3)

                Text {
                  Layout.fillWidth: true
                  text: root.t("contextTitle", "🧠 CONTEXT & SUBAGENTS")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }

                // Subagents Pill
                Rectangle {
                  height: 20
                  implicitWidth: subPillRow.implicitWidth + 12
                  radius: 4
                  color: root.activeSubagents > 0 ? Qt.rgba(root.gpuColor.r, root.gpuColor.g, root.gpuColor.b, 0.18) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                  border.color: root.activeSubagents > 0 ? root.gpuColor : root.cardBorder
                  border.width: 1
                  Layout.alignment: Qt.AlignRight

                  Row {
                    id: subPillRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                      text: root.activeSubagents > 0 ? ("󰁯 " + root.activeSubagents + " " + root.t("subagentsActive", "Active")) : ("󰁯 " + root.t("noSubagents", "No Subagents"))
                      color: root.activeSubagents > 0 ? root.gpuColor : root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: root.activeSubagents > 0
                    }
                  }
                }
              }

              // Context Usage Bar
              RowLayout {
                width: parent.width
                Text {
                  text: root.t("contextMax", "Context Window (1M Max):")
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.contextTokensStr + " (" + root.contextPct + "%)"
                  color: root.primaryAccent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }

              Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: root.track

                Rectangle {
                  height: parent.height
                  width: Math.min(parent.width, Math.max(4, parent.width * (root.contextPct / 100)))
                  radius: 3
                  color: root.contextPct > 80 ? root.criticalColor : (root.contextPct > 50 ? root.warningColor : root.primaryAccent)
                  Behavior on width { NumberAnimation { duration: 250 } }
                }
              }
            }
          }

          // 4. Developer Productivity & Time Saved Card (v1.2)
          Rectangle {
            width: parent.width
            implicitHeight: prodCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: prodCardCol
              anchors.fill: parent
              anchors.margins: Style.space(4)
              spacing: Style.space(3)

              RowLayout {
                width: parent.width
                Text {
                  text: root.t("prodTitle", "⚡ DEV PRODUCTIVITY & TIME SAVED")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.productivityData && root.productivityData.timeSavedStr ? root.productivityData.timeSavedStr : "~28h saved"
                  color: root.uploadColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }

              // 3-Col Productivity Grid
              RowLayout {
                width: parent.width
                spacing: Style.space(4)

                // Metric 1: Saved Dev Hours
                Rectangle {
                  Layout.fillWidth: true
                  height: 48
                  radius: 6
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.cardBorder
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: root.productivityData && root.productivityData.timeSavedStr ? root.productivityData.timeSavedStr.replace(" saved", "") : "28.8h"
                      color: root.uploadColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: root.t("devTimeSaved", "Dev Time Saved")
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption - 1
                    }
                  }
                }

                // Metric 2: Tools Executed
                Rectangle {
                  Layout.fillWidth: true
                  height: 48
                  radius: 6
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.cardBorder
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: String(root.totalToolCalls || (root.productivityData && root.productivityData.toolsExecuted) || 0)
                      color: root.primaryAccent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: root.t("toolsRun", "Tools Run")
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption - 1
                    }
                  }
                }

                // Metric 3: Tokens Processed
                Rectangle {
                  Layout.fillWidth: true
                  height: 48
                  radius: 6
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.color: root.cardBorder
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: root.productivityData && root.productivityData.tokensProcessedStr ? root.productivityData.tokensProcessedStr : "~6.2M"
                      color: root.memoryColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: root.t("tokensProcessed", "Tokens Processed")
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption - 1
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

              // Header Row (Title on left, Online/Offline Pill centered in total width)
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

                // Online/Offline Status Pill (Centered in total width)
                Rectangle {
                  id: gcpPillBox
                  readonly property bool isOnline: (!root.gcpInfo || root.gcpInfo.status === "Online" || root.gcpInfo.status === "Operational" || (root.gcpInfo.latencyMs > 0))
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  height: 20
                  width: gcpStatusRow.implicitWidth + 14
                  radius: 4
                  color: isOnline ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.12) : Qt.rgba(root.criticalColor.r, root.criticalColor.g, root.criticalColor.b, 0.12)
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
                  color: sessionMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  border.color: modelData.isActive ? (modelData.type === "ide" ? root.gpuColor : root.primaryAccent) : root.cardBorder
                  border.width: 1

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
                      border.color: modelData.type === "ide" ? root.gpuColor : root.cpuColor
                      border.width: 1

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
                      color: copyBtnMouse.containsMouse ? root.cardHover : root.cardFill
                      border.color: copyBtnBox.copied ? root.uploadColor : (copyBtnMouse.containsMouse ? root.downloadColor : root.cardBorder)
                      border.width: 1
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
                      color: launchMouse.containsMouse ? root.cardHover : root.cardFill
                      border.color: launchMouse.containsMouse ? root.primaryAccent : root.cardBorder
                      border.width: 1
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
                    width: (parent.width - Style.space(3)) / 2
                    height: 42
                    radius: 6
                    color: isSubWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.10) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                    border.color: isSubWorking ? root.uploadColor : Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.30)
                    border.width: isSubWorking ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: Style.space(3)
                      spacing: Style.space(3)

                      Rectangle {
                        width: 26
                        height: 26
                        radius: 4
                        color: isSubWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.25) : Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.12)
                        border.color: isSubWorking ? root.uploadColor : root.primaryAccent
                        border.width: 1

                        Text {
                          anchors.centerIn: parent
                          text: modelData.icon || "󰒃"
                          color: isSubWorking ? root.uploadColor : root.primaryAccent
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

                      Rectangle {
                        width: isSubWorking ? 54 : 44
                        height: 18
                        radius: 3
                        color: isSubWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.20) : Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.15)
                        border.color: isSubWorking ? root.uploadColor : root.primaryAccent
                        border.width: 1

                        Text {
                          anchors.centerIn: parent
                          text: isSubWorking ? root.t("subWorking", "Working 💓") : root.t("subReady", "Ready")
                          color: isSubWorking ? root.uploadColor : root.primaryAccent
                          font.family: root.fontFamily
                          font.pixelSize: 8
                          font.bold: true
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
                Item { Layout.fillWidth: true }
                // Online Pill (Green when online, Red if offline)
                Rectangle {
                  height: 18
                  width: localGpuStatusRow.implicitWidth + 10
                  radius: 3
                  color: (root.localAiInfo && root.localAiInfo.status === "Online") ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.15) : Qt.rgba(root.criticalColor.r, root.criticalColor.g, root.criticalColor.b, 0.15)
                  border.color: (root.localAiInfo && root.localAiInfo.status === "Online") ? root.uploadColor : root.criticalColor
                  border.width: 1

                  Row {
                    id: localGpuStatusRow
                    anchors.centerIn: parent
                    spacing: 3
                    Text {
                      text: "● " + ((root.localAiInfo && root.localAiInfo.status) ? root.localAiInfo.status : "Online")
                      color: (root.localAiInfo && root.localAiInfo.status === "Online") ? root.uploadColor : root.criticalColor
                      font.family: root.fontFamily
                      font.pixelSize: 8
                      font.bold: true
                    }
                  }
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
                        name: "qwen2.5-coder:7b",
                        desc: root.t("qwenDesc", "Fast Code & Syntax"),
                        icon: "󰘦",
                        isWorking: (root.localAiInfo && root.localAiInfo.qwenWorking) || false
                      },
                      {
                        name: "deepseek-r1:7b",
                        desc: root.t("deepseekDesc", "Reasoning & Audit"),
                        icon: "󰚩",
                        isWorking: (root.localAiInfo && root.localAiInfo.deepseekWorking) || false
                      }
                    ]

                    Rectangle {
                      readonly property bool isModelWorking: modelData.isWorking
                      width: (parent.width - Style.space(3)) / 2
                      height: 42
                      radius: 6
                      color: isModelWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.10) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                      border.color: isModelWorking ? root.uploadColor : Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.30)
                      border.width: isModelWorking ? 2 : 1

                      RowLayout {
                        anchors.fill: parent
                        anchors.margins: Style.space(3)
                        spacing: Style.space(3)

                        Rectangle {
                          width: 26
                          height: 26
                          radius: 4
                          color: isModelWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.25) : Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.12)
                          border.color: isModelWorking ? root.uploadColor : root.primaryAccent
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: isModelWorking ? "⚡" : modelData.icon
                            color: isModelWorking ? root.uploadColor : root.primaryAccent
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.bodySmall
                          }
                        }

                        Column {
                          Layout.fillWidth: true
                          spacing: 1

                          Text {
                            text: modelData.name
                            color: isModelWorking ? root.uploadColor : root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                          }

                          Text {
                            text: isModelWorking ? root.t("subWorking", "Working 💓") : modelData.desc
                            color: root.dim
                            font.family: root.fontFamily
                            font.pixelSize: 8
                            elide: Text.ElideRight
                            width: parent.width
                          }
                        }

                        Rectangle {
                          width: isModelWorking ? 54 : 44
                          height: 18
                          radius: 3
                          color: isModelWorking ? Qt.rgba(root.uploadColor.r, root.uploadColor.g, root.uploadColor.b, 0.20) : Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.15)
                          border.color: isModelWorking ? root.uploadColor : root.primaryAccent
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: isModelWorking ? root.t("subWorking", "Working 💓") : root.t("subReady", "Ready")
                            color: isModelWorking ? root.uploadColor : root.primaryAccent
                            font.family: root.fontFamily
                            font.pixelSize: 8
                            font.bold: true
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
                  border.color: root.cardBorder
                  border.width: 1

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

          // Card 4: Tools Distribution Card (Enlarged Donut Pie Chart, Stats Legend & Summary)
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
                  text: root.t("toolsTitle", "🛠️ TOOL CALLS BREAKDOWN")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.t("total", "Total") + ": " + root.totalToolCalls + " " + root.t("totalCalls", "calls")
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
                    readonly property var sliceColors: root.sliceColors
                    onVisibleChanged: if (visible) requestPaint()

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

                        ctx.fillStyle = root.sliceColors[i % root.sliceColors.length]
                        ctx.fill()

                        startAngle += sliceAngle
                      }
                    }

                    Connections {
                      target: root
                      function onToolsListChanged() {
                        if (root.popupOpen && root.selectedTab === 1 && toolDonutCanvas.visible) {
                          toolDonutCanvas.requestPaint()
                        }
                      }
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
                      text: root.t("totalCalls", "calls")
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
                    model: root.topToolsList

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
                          color: (toolDonutCanvas.sliceColors && toolDonutCanvas.sliceColors.length > 0) ? toolDonutCanvas.sliceColors[index % toolDonutCanvas.sliceColors.length] : root.primaryAccent
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
                          color: (toolDonutCanvas.sliceColors && toolDonutCanvas.sliceColors.length > 0) ? toolDonutCanvas.sliceColors[index % toolDonutCanvas.sliceColors.length] : root.primaryAccent
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

          // Card 4: 🌐 Language & Localization (8 languages)
          Rectangle {
            width: parent.width
            implicitHeight: langCardCol.implicitHeight + Style.space(8)
            radius: 8
            color: root.cardFill
            border.color: root.cardBorder
            border.width: 1

            Column {
              id: langCardCol
              width: parent.width - Style.space(8)
              anchors.centerIn: parent
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  text: root.t("langTitle", "🌐 LANGUAGE & LOCALIZATION")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                  text: root.currentLang.toUpperCase()
                  color: root.primaryAccent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }

              // 8-language grid (4x2)
              Grid {
                columns: 4
                width: parent.width
                spacing: Style.space(3)

                Repeater {
                  model: [
                    { code: "cs", flag: "🇨🇿", name: "Čeština" },
                    { code: "en", flag: "🇬🇧", name: "English" },
                    { code: "uk", flag: "🇺🇦", name: "Українська" },
                    { code: "it", flag: "🇮🇹", name: "Italiano" },
                    { code: "de", flag: "🇩🇪", name: "Deutsch" },
                    { code: "es", flag: "🇪🇸", name: "Español" },
                    { code: "fr", flag: "🇫🇷", name: "Français" },
                    { code: "ja", flag: "🇯🇵", name: "日本語" }
                  ]

                  Rectangle {
                    width: (parent.width - 3 * Style.space(3)) / 4
                    height: 32
                    radius: 5
                    color: root.currentLang === modelData.code ? Qt.rgba(root.primaryAccent.r, root.primaryAccent.g, root.primaryAccent.b, 0.15) : (langBtnMouse.containsMouse ? root.cardHover : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03))
                    border.color: root.currentLang === modelData.code ? root.primaryAccent : root.cardBorder
                    border.width: 1

                    RowLayout {
                      anchors.centerIn: parent
                      spacing: 3
                      Text {
                        text: modelData.flag
                        font.pixelSize: Style.font.caption
                      }
                      Text {
                        text: modelData.name
                        color: root.currentLang === modelData.code ? root.primaryAccent : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: root.currentLang === modelData.code
                        elide: Text.ElideRight
                        Layout.maximumWidth: 62
                      }
                    }

                    MouseArea {
                      id: langBtnMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.setLanguage(modelData.code)
                    }
                  }
                }
              }
            }
          }

          // Card 5: 🔧 System & Environment Integration
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
                  text: root.t("sysTitle", "🔧 SYSTEM & PLUGIN ENVIRONMENT")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: "v1.2-preview · Local Pro"
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
                      text: root.t("planTier", "Plan Tier")
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
                      text: root.t("activeModel", "Active Model")
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
