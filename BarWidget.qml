import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.bolens.privacy-devices"
  manageIpc: false

  readonly property var privacyService: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var configuredOrder: Model.arraySetting(setting("order", []), Model.KINDS)
  readonly property bool showIdle: setting("showIdle", true) === true
  readonly property string displayMode: String(setting("displayMode", "icons"))
  readonly property bool showControls: setting("showControls", true) === true
  readonly property real idleOpacity: Math.max(0.1, Math.min(1, Number(setting("idleOpacity", 0.45))))
  readonly property real disabledOpacity: Math.max(0.25, Math.min(1, Number(setting("disabledOpacity", 1))))
  readonly property string statusMarkerMode: String(setting("statusMarkerMode", "symbols"))
  readonly property string statePillStyle: String(setting("statePillStyle", "filled"))
  readonly property string popupDensity: String(setting("popupDensity", "comfortable"))
  readonly property bool showStatePills: setting("showStatePills", true) === true
  readonly property bool showSessionCounts: setting("showSessionCounts", true) === true
  readonly property bool animatePending: setting("animatePending", true) === true
  readonly property color activeThemeColor: themeColor(String(setting("activeColorRole", "bar-active")), true)
  readonly property color inactiveThemeColor: themeColor(String(setting("inactiveColorRole", "muted")), false)
  readonly property color disabledThemeColor: themeColor(String(setting("disabledColorRole", "urgent")), true)
  readonly property color mutedThemeColor: themeColor(String(setting("mutedColorRole", "urgent")), true)
  readonly property color unmutedThemeColor: themeColor(String(setting("unmutedColorRole", "foreground")), false)
  readonly property var visibleItems: buildVisibleItems()
  readonly property var activitySourceItems: orderedKinds().map(function(kind) { return item(kind) })
  readonly property int activeCount: activeItems().length
  readonly property bool monitoringDegraded: privacyService && typeof privacyService.monitoringDegraded === "function" ? privacyService.monitoringDegraded() : false
  readonly property var kindOptions: [
    {value: "microphone", label: "Microphone"}, {value: "audio-output", label: "Audio output"},
    {value: "camera", label: "Camera"}, {value: "screen-share", label: "Screen sharing"},
    {value: "screenshot", label: "Screenshot"}, {value: "screen-recording", label: "Screen recording"},
    {value: "location", label: "Location"}
  ]
  readonly property var normalBarItems: displayMode === "active-count"
    ? [{kind: "summary", label: "Privacy", icon: activeCount > 0 ? "󰒃 " + activeCount : "󰒃", active: activeCount > 0, apps: [], controllable: false, controlEnabled: false, health: {status: "healthy"}, sessions: []}]
    : (displayMode === "active-only" ? activeItems() : visibleItems)
  readonly property var barItems: monitoringDegraded && normalBarItems.length === 0
    ? [{kind: "summary", label: "Privacy", icon: "󰀦", active: false, apps: [], controllable: false, controlEnabled: false, health: {status: "degraded"}, sessions: []}]
    : normalBarItems
  property string editingKind: ""
  property bool showingGlobalSettings: false
  property bool settingsMutationPending: false
  property string globalSettingsPage: "general"
  property string selectedKind: ""
  property var displayedActivityItems: []
  property var deferredActivityItems: null
  property int handledSettingsRequestSerial: 0
  property double durationNow: Date.now()
  property string settingsTransferStatus: ""
  readonly property real openPanelIndicatorWidth: button.labelWidth

  function setting(key, fallback) {
    return settings && settings[key] !== undefined ? settings[key] : fallback
  }

  function syncService() {
    if (privacyService && typeof privacyService.configure === "function") privacyService.configure(Model.sanitizeSettings(settings))
  }

  function showGlobalSettings(page) {
    editingKind = ""
    showingGlobalSettings = true
    globalSettingsPage = Model.settingsPage(page)
    contentFlick.contentY = 0
  }

  function showActivity() {
    editingKind = ""
    showingGlobalSettings = false
    contentFlick.contentY = 0
  }

  function closeCurrentLayer() {
    if (editingKind !== "") { editingKind = ""; return }
    if (showingGlobalSettings) { showActivity(); return }
    close()
  }

  function moveActivitySelection(delta) {
    var rows = displayedActivityItems
    if (!rows.length) { selectedKind = ""; return }
    var index = rows.findIndex(function(entry) { return entry.kind === selectedKind })
    index = Math.max(0, Math.min(rows.length - 1, (index < 0 ? 0 : index) + delta))
    selectedKind = rows[index].kind
  }

  function activateActivitySelection() {
    if (!selectedKind && displayedActivityItems.length) selectedKind = displayedActivityItems[0].kind
    if (selectedKind) { showingGlobalSettings = false; editingKind = selectedKind; contentFlick.contentY = 0 }
  }

  function activityStateChanged(next) {
    if (next.length !== displayedActivityItems.length) return true
    for (var index = 0; index < next.length; index++) {
      var old = displayedActivityItems[index]
      if (!old || old.kind !== next[index].kind || old.active !== next[index].active
          || old.controlEnabled !== next[index].controlEnabled || old.pending !== next[index].pending
          || old.health.status !== next[index].health.status) return true
    }
    return false
  }

  function syncDisplayedItems() {
    var next = activitySourceItems
    // Never defer privacy state changes; only defer non-critical text/session churn.
    if (contentFlick.moving && !activityStateChanged(next)) deferredActivityItems = next
    else { displayedActivityItems = next; deferredActivityItems = null }
  }

  function flushDeferredItems() {
    if (deferredActivityItems !== null) {
      displayedActivityItems = deferredActivityItems
      deferredActivityItems = null
    }
  }

  function monitoringTelemetryText() {
    if (!privacyService || typeof privacyService.monitoringTelemetry !== "function") return "Monitoring telemetry unavailable"
    var data = privacyService.monitoringTelemetry()
    return "PipeWire: " + (data.pipewireReactive ? "reactive" : "unavailable")
      + "\nSession state: " + (data.lastSessionRefreshAgeSeconds < 0 ? "waiting" : data.lastSessionRefreshAgeSeconds + "s ago")
      + "\nFallback probes: " + (data.lastFallbackRefreshAgeSeconds < 0 ? "waiting" : data.lastFallbackRefreshAgeSeconds + "s ago")
      + " · observer " + (data.fallbackObserverRunning ? "running" : "retrying")
      + "\nDirect-device observer: " + (data.directDeviceEnabled ? (data.directObserverRunning ? "running" : "retrying") : "disabled")
      + (data.directDeviceEnabled ? " · heartbeat " + (data.directHeartbeatAgeSeconds < 0 ? "waiting" : data.directHeartbeatAgeSeconds + "s ago") + " · retry " + data.directObserverRetryMilliseconds + "ms" : "")
  }

  function commaList(value) {
    return Model.unique(String(value || "").split(",").map(function(entry) { return entry.trim() }).filter(Boolean))
  }

  function item(kind) {
    var apps = privacyService ? privacyService.appsFor(kind) : []
    return {
      kind: kind,
      label: labelFor(kind),
      icon: iconFor(kind),
      active: privacyService ? privacyService.active(kind) : false,
      apps: apps,
      controllable: privacyService ? privacyService.controllable(kind) : false,
      controlEnabled: privacyService ? privacyService.controlEnabled(kind) : false,
      pending: privacyService && typeof privacyService.controlPending === "function" ? privacyService.controlPending(kind) : false,
      dependenciesReady: privacyService && typeof privacyService.dependenciesReady === "function" ? privacyService.dependenciesReady(kind) : true,
      health: privacyService && typeof privacyService.healthFor === "function" ? privacyService.healthFor(kind) : {status: "healthy", summary: ""},
      sessions: privacyService && typeof privacyService.attributedSessionsFor === "function" ? privacyService.attributedSessionsFor(kind) : []
    }
  }

  function themeColor(role, activeFallback) {
    if (role === "bar-active") return Color.bar.active
    if (role === "urgent") return Color.urgent
    if (role === "accent") return Color.accent
    if (role === "foreground") return bar ? bar.barForeground : Color.foreground
    if (role === "muted") return Color.muted
    return activeFallback ? Color.bar.active : Color.muted
  }

  function controlDescription(entry) {
    if (!entry.dependenciesReady && privacyService) return privacyService.dependencyDescription(entry.kind) + ". Click to install."
    if (entry.pending) return "Waiting for authorization; the device state will be verified when the action finishes"
    if (entry.kind === "microphone") return entry.controlEnabled ? "Input is available; turn off to mute" : "Input is muted; turn on to unmute"
    if (entry.kind === "audio-output") return entry.controlEnabled ? "Output is available; turn off to mute" : "Output is muted; turn on to unmute"
    if (entry.kind === "screen-recording") return entry.controlEnabled ? "Recording is active; turn off to stop" : "Turn on to open the recording picker"
    if (entry.kind === "screenshot") return "Take a screenshot"
    if (entry.kind === "camera") return entry.controlEnabled ? "Camera is allowed; turn off to block the camera driver" : "Camera is blocked; turn on to allow it"
    if (entry.kind === "screen-share") return entry.controlEnabled ? "Screen sharing is allowed; turn off to block the Hyprland portal" : "Screen sharing is blocked; turn on to allow it"
    if (entry.kind === "location") return entry.controlEnabled ? "Location is allowed; turn off to block GeoClue" : "Location is blocked; turn on to allow it"
    return "Status only"
  }

  function diagnosticText(kind) {
    if (!privacyService || typeof privacyService.diagnostic !== "function") return "Diagnostics unavailable"
    var data = privacyService.diagnostic(kind)
    var apps = data.apps && data.apps.length ? data.apps.join(", ") : "None detected"
    var probe = data.probeExitCode < 0 ? "Not run" : String(data.probeExitCode)
    var control = data.controlExitCode < 0 ? "Not used" : String(data.controlExitCode)
    var codes = data.health.codes && data.health.codes.length ? data.health.codes.join(", ") : "ok"
    var transaction = data.controlTransaction ? data.controlTransaction.status + " (" + data.controlTransaction.code + ")" : "None"
    return "Backend: " + data.backend
      + "\nDependencies: " + (data.dependenciesReady ? "Ready" : data.dependencyDescription)
      + "\nMonitoring: " + data.health.status + (data.health.summary ? " · " + data.health.summary : "")
      + "\nDiagnostic codes: " + codes
      + "\nActivity: " + (data.active ? "Active" : "Idle")
      + "\nApplications: " + apps
      + "\nControl: " + data.controlState
      + " · Transaction: " + transaction
      + "\nLast probe exit: " + probe
      + " · Last control exit: " + control
  }

  function isAudioControl(entry) {
    return entry.kind === "microphone" || entry.kind === "audio-output"
  }

  function isPreventativeControl(entry) {
    return ["camera", "screen-share", "location"].indexOf(entry.kind) >= 0
  }

  function itemVisualState(entry) {
    return Model.privacyVisualState(entry)
  }

  function itemStateLabel(entry) { return Model.privacyStateLabel(entry) }
  function itemStatusMarkerVisible(kind) {
    var visibility = setting("itemStatusMarkerVisibility", {}) || {}
    return visibility[kind] === undefined ? true : visibility[kind] === true
  }
  function itemStateMarker(entry) {
    return Model.privacyStateMarker(entry, statusMarkerMode, itemStatusMarkerVisible(entry.kind))
  }
  function itemSessionCount(entry) { return Model.privacySessionCount(entry, showSessionCounts) }

  function barItemText(entry) {
    var suffix = itemStateMarker(entry)
    var count = itemSessionCount(entry)
    return entry.icon + (suffix ? " " + suffix : "") + (count ? String(count) : "")
  }

  function itemColor(entry) {
    var state = itemVisualState(entry)
    if (state === "unavailable") return Color.urgent
    if (state === "pending") return Color.accent
    var roles = setting("itemColorRoles", {}) || {}
    var override = roles[entry.kind] || {}
    if (isAudioControl(entry)) return entry.controlEnabled
      ? themeColor(String(override.unmuted || setting("unmutedColorRole", "foreground")), false)
      : themeColor(String(override.muted || setting("mutedColorRole", "urgent")), true)
    if (state === "disabled") return themeColor(String(override.disabled || setting("disabledColorRole", "urgent")), true)
    return state === "active"
      ? themeColor(String(override.active || setting("activeColorRole", "bar-active")), true)
      : themeColor(String(override.inactive || setting("inactiveColorRole", "muted")), false)
  }

  function persistSettings(values) {
    var candidate = {}
    for (var existing in settings) if (existing !== "id") candidate[existing] = settings[existing]
    for (var key in values) candidate[key] = values[key]
    var clean = Model.sanitizeSettings(candidate)
    var entry = {id: moduleName}
    for (var sanitizedKey in clean) entry[sanitizedKey] = clean[sanitizedKey]
    settings = entry
    syncService()
    settingsMutationPending = true
    settingsMutationGuard.restart()
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function") {
      bar.shell.updateEntryInline(moduleName, entry)
      Qt.callLater(function() { if (!root.opened) root.open() })
    }
  }

  function settingsHelperPath() {
    return String(Qt.resolvedUrl("privacy-settings")).replace(/^file:\/\//, "")
  }

  function exportSettings() {
    settingsTransferStatus = "Exporting…"
    settingsTransferProc.mode = "export"
    settingsTransferProc.command = [settingsHelperPath(), "export", JSON.stringify(Model.sanitizeSettings(settings))]
    settingsTransferProc.running = true
  }

  function importSettings() {
    settingsTransferStatus = "Importing…"
    settingsTransferProc.mode = "import"
    settingsTransferProc.command = [settingsHelperPath(), "import"]
    settingsTransferProc.running = true
  }

  function addPolicyValue(key, value) {
    var values = Model.arraySetting(setting(key, []), [])
    if (values.map(function(entry) { return entry.toLowerCase() }).indexOf(String(value).toLowerCase()) === -1) values.push(String(value))
    var update = {}
    update[key] = values
    persistSettings(update)
  }

  function clearPolicy(key) {
    var update = {}
    update[key] = []
    persistSettings(update)
  }

  function resetGlobalSettings() {
    persistSettings({
      enabledKinds: Model.KINDS.slice(),
      notificationKinds: ["microphone", "camera", "screen-share", "screen-recording", "location"],
      blockableKinds: ["camera", "screen-share", "location"],
      showIdle: true,
      displayMode: "icons",
      showControls: true,
      idleOpacity: 0.45,
      disabledOpacity: 1,
      statusMarkerMode: "symbols",
      statePillStyle: "filled",
      popupDensity: "comfortable",
      showStatePills: true,
      showSessionCounts: true,
      animatePending: true,
      deduplicateApps: true,
      notifyOnActivity: true,
      notifyOnStop: false,
      notifyOnControlChanges: true,
      historyEnabled: false,
      hiddenApps: [],
      notificationSuppressedApps: [],
      directDeviceMonitoring: false,
      showInferredAttribution: true,
      directDevicePollSeconds: 5,
      locationPollSeconds: 15,
      recordingPollSeconds: 2,
      popupMaxHeight: 620,
      activeColorRole: "bar-active",
      inactiveColorRole: "muted",
      disabledColorRole: "urgent",
      mutedColorRole: "urgent",
      unmutedColorRole: "foreground"
    })
  }

  function persistIcon(kind, value) {
    var icons = JSON.parse(JSON.stringify(setting("icons", {}) || {}))
    icons[kind] = String(value || "")
    persistSettings({icons: icons})
  }

  function labelFor(kind) {
    var labels = setting("itemLabels", {}) || {}
    return labels[kind] !== undefined && String(labels[kind]) !== "" ? String(labels[kind]) : Model.label(kind)
  }

  function persistLabel(kind, value) {
    var labels = JSON.parse(JSON.stringify(setting("itemLabels", {}) || {}))
    var text = String(value || "").trim()
    if (text) labels[kind] = text
    else delete labels[kind]
    persistSettings({itemLabels: labels})
  }

  function persistItemColor(kind, state, role) {
    var roles = JSON.parse(JSON.stringify(setting("itemColorRoles", {}) || {}))
    if (!roles[kind]) roles[kind] = {}
    roles[kind][state] = role
    persistSettings({itemColorRoles: roles})
  }

  function persistItemStatusMarker(kind, visible) {
    var visibility = JSON.parse(JSON.stringify(setting("itemStatusMarkerVisibility", {}) || {}))
    visibility[kind] = visible === true
    persistSettings({itemStatusMarkerVisibility: visibility})
  }

  function itemColorRole(kind, state, fallback) {
    var roles = setting("itemColorRoles", {}) || {}
    return roles[kind] && roles[kind][state] ? String(roles[kind][state]) : fallback
  }

  function moveItem(kind, delta) {
    var order = orderedKinds()
    var index = order.indexOf(kind)
    var target = index + delta
    if (index < 0 || target < 0 || target >= order.length) return
    var swap = order[target]
    order[target] = order[index]
    order[index] = swap
    persistSettings({order: order})
  }

  function itemShowsWhenIdle(kind) {
    var overrides = setting("itemIdleVisibility", {}) || {}
    return overrides[kind] !== undefined ? overrides[kind] === true : showIdle
  }

  function persistItemIdleVisibility(kind, visible) {
    var overrides = JSON.parse(JSON.stringify(setting("itemIdleVisibility", {}) || {}))
    overrides[kind] = visible === true
    persistSettings({itemIdleVisibility: overrides})
  }

  function itemIdleOpacity(kind) {
    var overrides = setting("itemIdleOpacity", {}) || {}
    var value = overrides[kind] !== undefined ? Number(overrides[kind]) : idleOpacity
    return Math.max(0.1, Math.min(1, isFinite(value) ? value : idleOpacity))
  }

  function persistItemIdleOpacity(kind, percent) {
    var overrides = JSON.parse(JSON.stringify(setting("itemIdleOpacity", {}) || {}))
    overrides[kind] = Math.max(10, Math.min(100, Number(percent))) / 100
    persistSettings({itemIdleOpacity: overrides})
  }

  function resetItemSettings(kind) {
    var icons = JSON.parse(JSON.stringify(setting("icons", {}) || {}))
    var roles = JSON.parse(JSON.stringify(setting("itemColorRoles", {}) || {}))
    var visibility = JSON.parse(JSON.stringify(setting("itemIdleVisibility", {}) || {}))
    var opacity = JSON.parse(JSON.stringify(setting("itemIdleOpacity", {}) || {}))
    var markerVisibility = JSON.parse(JSON.stringify(setting("itemStatusMarkerVisibility", {}) || {}))
    var labels = JSON.parse(JSON.stringify(setting("itemLabels", {}) || {}))
    delete icons[kind]
    delete roles[kind]
    delete visibility[kind]
    delete opacity[kind]
    delete markerVisibility[kind]
    delete labels[kind]
    persistSettings({icons: icons, itemColorRoles: roles, itemIdleVisibility: visibility, itemIdleOpacity: opacity, itemStatusMarkerVisibility: markerVisibility, itemLabels: labels})
  }

  function toggleEntry(entry) {
    if (!privacyService || !entry.controllable) return
    if (!entry.dependenciesReady) {
      privacyService.installDependencies(entry.kind)
      return
    }
    if (entry.kind === "screen-recording") {
      privacyService.beginExternalControl("screen-recording", !entry.controlEnabled)
      var backend = String(setting("recordingBackend", "omarchy"))
      if (backend === "wf-recorder")
        bar.run(privacyService.dependencyHelperPath().replace("privacy-deps", "privacy-recording") + (entry.controlEnabled ? " stop wf-recorder" : " start wf-recorder"))
      else if (backend === "custom") {
        var command = String(setting(entry.controlEnabled ? "recordingCustomStopCommand" : "recordingCustomStartCommand", ""))
        if (command) bar.run(command)
      }
      else if (entry.controlEnabled) bar.run("omarchy-capture-screenrecording --stop-recording")
      else bar.run("omarchy-menu toggle trigger.capture.screenrecord")
      return
    }
    if (entry.kind === "screenshot") {
      var screenshotBackend = String(setting("screenshotBackend", "omarchy"))
      if (screenshotBackend === "custom") {
        var screenshotCommand = String(setting("screenshotCustomCommand", ""))
        if (screenshotCommand) bar.run(screenshotCommand)
      }
      else if (screenshotBackend === "omarchy") bar.run("omarchy-capture-screenshot")
      else bar.run(privacyService.dependencyHelperPath().replace("privacy-deps", "privacy-screenshot") + " capture " + screenshotBackend)
      return
    }
    privacyService.toggleControl(entry.kind)
  }

  function enabled(kind) {
    return privacyService ? privacyService.kindEnabled(kind) : Model.arraySetting(setting("enabledKinds", Model.KINDS), Model.KINDS).indexOf(kind) !== -1
  }

  function orderedKinds() {
    var result = []
    for (var index = 0; index < configuredOrder.length; index++) {
      var kind = configuredOrder[index]
      if (enabled(kind) && result.indexOf(kind) === -1) result.push(kind)
    }
    for (var fallbackIndex = 0; fallbackIndex < Model.KINDS.length; fallbackIndex++) {
      var fallbackKind = Model.KINDS[fallbackIndex]
      if (enabled(fallbackKind) && result.indexOf(fallbackKind) === -1) result.push(fallbackKind)
    }
    return result
  }

  function buildVisibleItems() {
    var result = []
    var kinds = orderedKinds()
    for (var index = 0; index < kinds.length; index++) {
      var entry = item(kinds[index])
      if (entry.active || itemShowsWhenIdle(entry.kind)) result.push(entry)
    }
    return result
  }

  function activeItems() {
    return visibleItems.filter(function(entry) { return entry.active })
  }

  function iconFor(kind) {
    var defaults = {"microphone":"󰍬", "audio-output":"󰓃", "camera":"󰄀", "screen-share":"󰍹", "screenshot":"󰹑", "screen-recording":"󰻂", "location":"󰋽"}
    var icons = setting("icons", {}) || {}
    return icons[kind] !== undefined ? String(icons[kind]) : String(defaults[kind] || "")
  }

  function sharedText(value) {
    return Model.autoTextSafe(value)
  }

  function barText() {
    if (displayMode === "active-count") return activeCount > 0 ? "󰒃 " + activeCount : (showIdle ? "󰒃" : "")
    var items = displayMode === "active-only" ? activeItems() : visibleItems
    return items.map(function(entry) { return entry.icon }).join(" ")
  }

  function tooltip() {
    if (activeCount === 0) return "Privacy devices idle"
    return activeItems().map(function(entry) {
      return sharedText(entry.label) + (entry.apps.length ? ": " + entry.apps.map(sharedText).join(", ") : " in use")
    }).join("\n")
  }

  function itemTooltip(entry) {
    if (entry.kind === "summary") return tooltip()
    var label = sharedText(entry.label)
    var visualState = itemVisualState(entry)
    var state = itemStateLabel(entry)
    if (visualState === "active" && entry.apps.length) state += " — " + entry.apps.map(sharedText).join(", ")
    else if (visualState === "unavailable" && entry.health.summary) state += " — " + sharedText(entry.health.summary)
    var action = !entry.dependenciesReady
      ? "Left click to install requirements"
      : entry.controllable
      ? (entry.kind === "screenshot"
          ? "Left click to take a screenshot"
          : entry.kind === "screen-recording"
          ? (entry.controlEnabled ? "Left click to stop recording" : "Left click to start recording")
          : root.isAudioControl(entry)
          ? (entry.controlEnabled ? "Left click to mute" : "Left click to unmute")
          : (entry.controlEnabled ? "Left click to block" : "Left click to allow"))
      : "Left click for details"
    return label + " · " + state
      + "\n" + action
      + "\nMiddle click for " + label.toLowerCase() + " settings"
      + "\nRight click for privacy details"
  }

  function pressItem(entry, buttonCode) {
    if (buttonCode === Qt.MiddleButton) {
      if (entry.kind === "summary") showGlobalSettings("general")
      else { showingGlobalSettings = false; editingKind = entry.kind }
      root.open()
      return
    }
    if (buttonCode === Qt.RightButton || entry.kind === "summary" || !entry.controllable) {
      editingKind = ""
      root.toggle()
      return
    }
    root.toggleEntry(entry)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  visible: root.barItems.length > 0

  onSettingsChanged: Qt.callLater(syncService)
  onPrivacyServiceChanged: Qt.callLater(syncService)
  onActivitySourceItemsChanged: syncDisplayedItems()
  onOpenedChanged: {
    if (opened) {
      durationNow = Date.now()
      if (privacyService && privacyService.settingsRequestSerial > handledSettingsRequestSerial) {
        handledSettingsRequestSerial = privacyService.settingsRequestSerial
        showGlobalSettings(privacyService.requestedSettingsPage)
      }
    }
    else if (settingsMutationPending) Qt.callLater(root.open)
    else {
      editingKind = ""
      showingGlobalSettings = false
      globalSettingsPage = "general"
      contentFlick.contentY = 0
    }
  }
  Component.onCompleted: { syncDisplayedItems(); Qt.callLater(syncService) }

  Timer {
    id: settingsMutationGuard
    interval: 2000
    onTriggered: root.settingsMutationPending = false
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.opened
    triggeredOnStart: true
    onTriggered: if (!contentFlick.moving) root.durationNow = Date.now()
  }

  Item {
    id: button
    implicitWidth: iconRow.implicitWidth
    implicitHeight: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal
    property real labelWidth: implicitWidth

    Row {
      id: iconRow
      anchors.centerIn: parent
      spacing: 0

      Repeater {
        model: root.barItems
        delegate: WidgetButton {
          required property var modelData
          bar: root.bar
          text: root.sharedText(root.barItemText(modelData))
          active: modelData.active
          dimmed: false
          foreground: root.itemColor(modelData)
          activeColor: root.itemColor(modelData)
          opacity: root.itemVisualState(modelData) === "idle" ? root.itemIdleOpacity(modelData.kind)
            : (root.itemVisualState(modelData) === "disabled" ? root.disabledOpacity : 1)
          SequentialAnimation on opacity {
            running: modelData.pending && root.animatePending
            loops: Animation.Infinite
            NumberAnimation { to: 0.45; duration: 450; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutQuad }
          }
          horizontalMargin: modelData.kind === "summary" ? 8.5 : 5
          tooltipText: root.itemTooltip(modelData)
          onPressed: function(buttonCode) { root.pressItem(modelData, buttonCode) }
        }
      }
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: fittedContentWidth(Style.space(460))
    contentHeight: fittedContentHeight(content.implicitHeight, Style.space(Math.max(360, Math.min(900, Number(root.setting("popupMaxHeight", 620)) || 620))))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.closeCurrentLayer()
      onMoveRequested: function(dx, dy) {
        if (dy !== 0 && root.editingKind === "" && !root.showingGlobalSettings) root.moveActivitySelection(dy)
      }
      onActivateRequested: {
        if (root.editingKind === "" && !root.showingGlobalSettings) root.activateActivitySelection()
      }
      onTextKey: function(text) {
        if ((text === "s" || text === "S") && root.editingKind === "") root.showGlobalSettings("general")
        else if ((text === "r" || text === "R") && !root.showingGlobalSettings && privacyService) privacyService.refreshFallbacks()
        else if (root.showingGlobalSettings && "123".indexOf(text) >= 0) {
          root.globalSettingsPage = ["general", "alerts", "monitoring"][Number(text) - 1]
          contentFlick.contentY = 0
        }
      }
      onTabRequested: function(direction) { if (bar && typeof bar.switchPanelFrom === "function") bar.switchPanelFrom(root, direction) }

      Flickable {
        id: contentFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        pixelAligned: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        onMovementEnded: root.flushDeferredItems()
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
          id: content
          width: contentFlick.width - (contentFlick.contentHeight > contentFlick.height ? Style.spacing.sm : 0)
          spacing: Style.spacing.md

        RowLayout {
          visible: root.editingKind === "" && !root.showingGlobalSettings
          Layout.fillWidth: true
          Text {
            text: "Privacy activity"
            textFormat: Text.PlainText
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.weight: Font.DemiBold
          }
          Item { Layout.fillWidth: true }
          Rectangle {
            implicitWidth: statusText.implicitWidth + Style.spacing.md * 2
            implicitHeight: statusText.implicitHeight + Style.spacing.sm
            radius: implicitHeight / 2
            color: Util.alpha(root.monitoringDegraded ? Color.urgent : (root.activeCount > 0 ? root.activeThemeColor : root.inactiveThemeColor), 0.14)
            Text {
              id: statusText
              anchors.centerIn: parent
              text: root.monitoringDegraded ? "󰀦  Degraded" : (root.activeCount > 0 ? root.activeCount + " active" : "All idle")
              textFormat: Text.PlainText
              color: root.monitoringDegraded ? Color.urgent : (root.activeCount > 0 ? root.activeThemeColor : root.inactiveThemeColor)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.weight: Font.DemiBold
            }
          }
          Button {
            iconText: "󰒓"
            tooltipText: "Global settings"
            horizontalPadding: Style.spacing.controlGap
            onClicked: root.showGlobalSettings("general")
          }
        }

        ColumnLayout {
          id: globalSettingsEditor
          visible: root.showingGlobalSettings
          Layout.fillWidth: true
          spacing: Style.spacing.md

          RowLayout {
            Layout.fillWidth: true
            Button { iconText: "󰁍"; tooltipText: "Back"; horizontalPadding: Style.spacing.controlGap; onClicked: root.showActivity() }
            Text { Layout.fillWidth: true; text: "Global settings"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.title; font.weight: Font.DemiBold }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.spacing.sm
            GlobalSettingsTab { label: "General"; value: "general" }
            GlobalSettingsTab { label: "Alerts & data"; value: "alerts" }
            GlobalSettingsTab { label: "Monitoring"; value: "monitoring" }
          }

          Loader {
            id: globalSettingsPageLoader
            Layout.fillWidth: true
            sourceComponent: root.globalSettingsPage === "general" ? generalSettingsPage
              : (root.globalSettingsPage === "alerts" ? alertsSettingsPage : monitoringSettingsPage)
          }

          Button { Layout.alignment: Qt.AlignRight; text: "Reset global settings"; onClicked: root.resetGlobalSettings() }
        }

        ColumnLayout {
          visible: root.editingKind !== "" && !root.showingGlobalSettings
          Layout.fillWidth: true
          spacing: Style.spacing.md

          RowLayout {
            Layout.fillWidth: true
            Button {
              text: "Back"
              iconText: "󰁍"
              onClicked: root.editingKind = ""
            }
            Text {
              Layout.fillWidth: true
              text: Model.label(root.editingKind) + " settings"
              textFormat: Text.PlainText
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.weight: Font.DemiBold
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: previewRow.implicitHeight + Style.spacing.md * 2
            radius: Style.cornerRadius
            color: Util.alpha(root.itemColor(root.item(root.editingKind)), 0.10)
            RowLayout {
              id: previewRow
              anchors.fill: parent
              anchors.margins: Style.spacing.md
              Text {
                text: root.barItemText(root.item(root.editingKind))
                textFormat: Text.PlainText
                color: root.itemColor(root.item(root.editingKind))
                font.family: Style.font.family
                font.pixelSize: Style.font.icon
              }
              Text {
                Layout.fillWidth: true
                text: root.labelFor(root.editingKind)
                textFormat: Text.PlainText
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.weight: Font.DemiBold
              }
            }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Appearance"
          }

          RowLayout {
            Layout.fillWidth: true
            TextField {
              id: labelEditor
              Layout.fillWidth: true
              placeholderText: "Display label"
              text: root.editingKind ? root.labelFor(root.editingKind) : ""
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistLabel(root.editingKind, text)
            }
            Button {
              text: "Save label"
              onClicked: root.persistLabel(root.editingKind, labelEditor.text)
            }
          }

          RowLayout {
            Layout.fillWidth: true
            TextField {
              id: iconEditor
              Layout.fillWidth: true
              placeholderText: "Icon"
              text: root.editingKind ? root.iconFor(root.editingKind) : ""
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistIcon(root.editingKind, text)
            }
            Button {
              text: "Save icon"
              onClicked: root.persistIcon(root.editingKind, iconEditor.text)
            }
          }

          Dropdown {
            Layout.fillWidth: true
            label: root.isAudioControl({kind: root.editingKind}) ? "Muted color" : "Active color"
            options: ["bar-active", "urgent", "accent", "foreground", "muted"]
            value: root.isAudioControl({kind: root.editingKind})
              ? root.itemColorRole(root.editingKind, "muted", String(root.setting("mutedColorRole", "urgent")))
              : root.itemColorRole(root.editingKind, "active", String(root.setting("activeColorRole", "bar-active")))
            onChanged: function(value) { root.persistItemColor(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "muted" : "active", value) }
          }

          Dropdown {
            visible: root.isPreventativeControl({kind: root.editingKind})
            Layout.fillWidth: true
            label: "Disabled color"
            options: ["bar-active", "urgent", "accent", "foreground", "muted"]
            value: root.itemColorRole(root.editingKind, "disabled", String(root.setting("disabledColorRole", "urgent")))
            onChanged: function(value) { root.persistItemColor(root.editingKind, "disabled", value) }
          }

          Dropdown {
            Layout.fillWidth: true
            label: root.isAudioControl({kind: root.editingKind}) ? "Unmuted color" : "Inactive color"
            options: ["bar-active", "urgent", "accent", "foreground", "muted"]
            value: root.isAudioControl({kind: root.editingKind})
              ? root.itemColorRole(root.editingKind, "unmuted", String(root.setting("unmutedColorRole", "foreground")))
              : root.itemColorRole(root.editingKind, "inactive", String(root.setting("inactiveColorRole", "muted")))
            onChanged: function(value) { root.persistItemColor(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "unmuted" : "inactive", value) }
          }

          NumberField {
            label: "Idle opacity (%)"
            from: 10
            to: 100
            stepSize: 5
            value: Math.round(root.itemIdleOpacity(root.editingKind) * 100)
            foreground: Color.popups.text
            accent: root.activeThemeColor
            fontFamily: Style.font.family
            onModified: function(value) { root.persistItemIdleOpacity(root.editingKind, value) }
          }

          Toggle {
            Layout.fillWidth: true
            label: "Show bar status marker"
            description: "Override marker visibility for this item."
            checked: root.itemStatusMarkerVisible(root.editingKind)
            foreground: Color.popups.text
            accent: root.activeThemeColor
            fontFamily: Style.font.family
            onClicked: root.persistItemStatusMarker(root.editingKind, !checked)
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Placement"
          }

          RowLayout {
            Layout.fillWidth: true
            Button {
              text: "Move left"
              onClicked: root.moveItem(root.editingKind, -1)
            }
            Button {
              text: "Move right"
              onClicked: root.moveItem(root.editingKind, 1)
            }
            Item { Layout.fillWidth: true }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Behavior"
          }

          Toggle {
            Layout.fillWidth: true
            label: "Show while idle"
            description: "Keep this item visible on the bar when it is not active."
            checked: root.itemShowsWhenIdle(root.editingKind)
            foreground: Color.popups.text
            accent: root.activeThemeColor
            fontFamily: Style.font.family
            onClicked: root.persistItemIdleVisibility(root.editingKind, !checked)
          }

          PanelSectionHeader {
            visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind})
            Layout.fillWidth: true
            text: "Backend"
          }

          Dropdown {
            visible: root.editingKind === "screen-recording"
            Layout.fillWidth: true
            label: "Recording backend"
            options: ["omarchy", "gpu-screen-recorder", "wf-recorder", "custom"]
            value: String(root.setting("recordingBackend", "omarchy"))
            onChanged: function(value) { root.persistSettings({recordingBackend: value}) }
          }

          Text {
            visible: root.editingKind === "screen-recording"
            Layout.fillWidth: true
            text: "Omarchy follows the system capture command. Explicit and custom choices keep dependency checks and activity detection tied to that backend."
            textFormat: Text.PlainText
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Dropdown {
            visible: root.editingKind === "screenshot"
            Layout.fillWidth: true
            label: "Screenshot backend"
            options: ["omarchy", "grim", "grim-satty", "hyprshot", "flameshot", "custom"]
            value: String(root.setting("screenshotBackend", "omarchy"))
            onChanged: function(value) { root.persistSettings({screenshotBackend: value}) }
          }

          Text {
            visible: root.editingKind === "screenshot"
            Layout.fillWidth: true
            text: "Omarchy uses its smart flow. Grim and Hyprshot capture regions; Grim + Satty and Flameshot add annotation."
            textFormat: Text.PlainText
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          ColumnLayout {
            visible: root.editingKind === "screenshot" && String(root.setting("screenshotBackend", "omarchy")) === "custom"
            Layout.fillWidth: true
            spacing: Style.spacing.sm
            TextField {
              id: customScreenshotCommandEditor
              Layout.fillWidth: true
              placeholderText: "Screenshot command"
              text: String(root.setting("screenshotCustomCommand", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({screenshotCustomCommand: text})
            }
            TextField {
              id: customScreenshotProcessEditor
              Layout.fillWidth: true
              placeholderText: "Activity process substring (optional)"
              text: String(root.setting("screenshotProcessName", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({screenshotProcessName: text})
            }
            Button {
              text: "Save custom backend"
              onClicked: root.persistSettings({
                screenshotCustomCommand: customScreenshotCommandEditor.text,
                screenshotProcessName: customScreenshotProcessEditor.text
              })
            }
          }

          ColumnLayout {
            visible: root.editingKind === "screen-recording" && String(root.setting("recordingBackend", "omarchy")) === "custom"
            Layout.fillWidth: true
            spacing: Style.spacing.sm
            TextField {
              id: customRecorderProcessEditor
              Layout.fillWidth: true
              placeholderText: "Process command substring"
              text: String(root.setting("recordingProcessName", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({recordingProcessName: text})
            }
            TextField {
              id: customRecorderStartEditor
              Layout.fillWidth: true
              placeholderText: "Start command"
              text: String(root.setting("recordingCustomStartCommand", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({recordingCustomStartCommand: text})
            }
            TextField {
              id: customRecorderStopEditor
              Layout.fillWidth: true
              placeholderText: "Stop command"
              text: String(root.setting("recordingCustomStopCommand", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({recordingCustomStopCommand: text})
            }
            Button {
              text: "Save custom backend"
              onClicked: root.persistSettings({
                recordingProcessName: customRecorderProcessEditor.text,
                recordingCustomStartCommand: customRecorderStartEditor.text,
                recordingCustomStopCommand: customRecorderStopEditor.text
              })
            }
          }

          Dropdown {
            visible: root.isAudioControl({kind: root.editingKind})
            Layout.fillWidth: true
            label: "Audio control backend"
            options: ["auto", "pactl", "wpctl"]
            value: String(root.setting("audioControlBackend", "auto"))
            onChanged: function(value) { root.persistSettings({audioControlBackend: value}) }
          }

          Text {
            visible: root.isAudioControl({kind: root.editingKind})
            Layout.fillWidth: true
            text: "Auto prefers pactl and falls back to wpctl. This changes mute control only; activity detection remains PipeWire-native."
            textFormat: Text.PlainText
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Diagnostics"
          }

          Button {
            visible: root.editingKind !== "" && privacyService && !privacyService.dependenciesReady(root.editingKind)
            text: "Install requirements"
            tooltipText: privacyService ? privacyService.dependencyDescription(root.editingKind) : ""
            onClicked: privacyService.installDependencies(root.editingKind)
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: diagnosticsText.implicitHeight + Style.spacing.md * 2
            radius: Style.cornerRadius
            color: Util.alpha(Color.popups.text, 0.04)
            Text {
              id: diagnosticsText
              anchors.fill: parent
              anchors.margins: Style.spacing.md
              text: root.diagnosticText(root.editingKind)
              textFormat: Text.PlainText
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Reset"
          }

          Button {
            text: "Reset item settings"
            tooltipText: "Restore the default label, icon, colors, idle opacity, and idle visibility"
            onClicked: {
              root.resetItemSettings(root.editingKind)
              iconEditor.text = root.iconFor(root.editingKind)
              labelEditor.text = root.labelFor(root.editingKind)
            }
          }
        }

        ColumnLayout {
          id: activityRows
          visible: root.editingKind === "" && !root.showingGlobalSettings
          Layout.fillWidth: true
          spacing: Style.spacing.md

          Repeater {
            // Do not retain main-widget delegates behind a settings/editor page.
            // An empty model prevents both visual leakage and needless bindings.
            model: root.editingKind === "" && !root.showingGlobalSettings
              ? root.displayedActivityItems
              : []
            delegate: PrivacyActivityCard {
              required property var modelData
              entry: modelData
              controller: root
            }
          }
        }

        ColumnLayout {
          visible: root.editingKind === "" && !root.showingGlobalSettings && Model.arraySetting(root.setting("hiddenApps", []), []).length > 0
          Layout.fillWidth: true
          spacing: Style.spacing.sm
          PanelSectionHeader { Layout.fillWidth: true; text: "Hidden applications" }
          Text {
            Layout.fillWidth: true
            text: Model.arraySetting(root.setting("hiddenApps", []), []).join(", ")
            textFormat: Text.PlainText
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Button { text: "Restore all"; onClicked: root.clearPolicy("hiddenApps") }
        }

        ColumnLayout {
          visible: root.editingKind === "" && !root.showingGlobalSettings && root.setting("historyEnabled", false) === true && privacyService && privacyService.recentHistory.length > 0
          Layout.fillWidth: true
          spacing: Style.spacing.sm
          PanelSectionHeader { Layout.fillWidth: true; text: "Recent activity" }
          Repeater {
            model: privacyService ? privacyService.recentHistory.slice(0, 5) : []
            delegate: Text {
              required property var modelData
              Layout.fillWidth: true
              text: Model.label(modelData.kind) + " · " + modelData.application + " · " + Model.formatDuration(modelData.durationMs) + " · " + modelData.source
              textFormat: Text.PlainText
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }
          Button { text: "Clear history"; onClicked: privacyService.clearHistory() }
        }

        Text {
          visible: root.editingKind === "" && !root.showingGlobalSettings
          Layout.fillWidth: true
          text: "Activity details distinguish observation source, attribution confidence, and control state. Middle-click an item for settings."
          textFormat: Text.PlainText
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
        }
      }
    }
  }

  Process {
    id: settingsTransferProc
    property string mode: ""
    stdout: StdioCollector { id: settingsTransferOutput; waitForEnd: true }
    stderr: StdioCollector { id: settingsTransferError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.settingsTransferStatus = "Transfer failed" + (settingsTransferError.text ? ": " + settingsTransferError.text.trim() : "")
        return
      }
      if (mode === "import") {
        try {
          root.persistSettings(JSON.parse(settingsTransferOutput.text))
          root.settingsTransferStatus = "Settings imported"
        } catch (error) { root.settingsTransferStatus = "Import returned invalid settings" }
      } else root.settingsTransferStatus = "Settings exported privately"
    }
  }

  Component {
    id: generalSettingsPage
    ColumnLayout {
      spacing: Style.spacing.md
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Behavior" }
        MultiSelect { Layout.fillWidth: true; label: "Monitored activity"; options: root.kindOptions; values: Model.arraySetting(root.setting("enabledKinds", Model.KINDS), Model.KINDS); foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { root.persistSettings({enabledKinds: values}) } }
        Toggle { Layout.fillWidth: true; label: "Show idle devices"; description: "Keep enabled privacy-device icons visible while idle."; checked: root.setting("showIdle", true) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({showIdle: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Show privacy controls"; description: "Show inline control switches and enable row actions."; checked: root.setting("showControls", true) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({showControls: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Deduplicate application names"; description: "List an application once when it owns several matching sessions."; checked: root.setting("deduplicateApps", true) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({deduplicateApps: !checked}) }
        Dropdown { Layout.fillWidth: true; label: "Bar presentation"; options: ["icons", "active-count", "active-only"]; value: String(root.setting("displayMode", "icons")); onChanged: function(value) { root.persistSettings({displayMode: value}) } }
        NumberField { label: "Default idle opacity (%)"; from: 10; to: 100; stepSize: 5; value: Math.round(Number(root.setting("idleOpacity", 0.45)) * 100); foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { root.persistSettings({idleOpacity: Number(value) / 100}) } }
        IntegerSetting { controller: root; settingKey: "popupMaxHeight"; label: "Popup maximum height"; minimum: 360; maximum: 900; fallback: 620; stepSize: 20 }
      }
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Theme colors" }
        Dropdown { Layout.fillWidth: true; label: "Active"; options: ["bar-active", "urgent", "accent", "foreground"]; value: String(root.setting("activeColorRole", "bar-active")); onChanged: function(value) { root.persistSettings({activeColorRole: value}) } }
        Dropdown { Layout.fillWidth: true; label: "Inactive"; options: ["muted", "foreground", "accent"]; value: String(root.setting("inactiveColorRole", "muted")); onChanged: function(value) { root.persistSettings({inactiveColorRole: value}) } }
        Dropdown { Layout.fillWidth: true; label: "Disabled"; options: ["urgent", "muted", "accent", "foreground", "bar-active"]; value: String(root.setting("disabledColorRole", "urgent")); onChanged: function(value) { root.persistSettings({disabledColorRole: value}) } }
        NumberField { label: "Disabled opacity (%)"; from: 25; to: 100; stepSize: 5; value: Math.round(root.disabledOpacity * 100); foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { root.persistSettings({disabledOpacity: Number(value) / 100}) } }
      }
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Status presentation" }
        Dropdown { Layout.fillWidth: true; label: "Bar status markers"; options: ["symbols", "letters", "off"]; value: root.statusMarkerMode; onChanged: function(value) { root.persistSettings({statusMarkerMode: value}) } }
        Dropdown { Layout.fillWidth: true; label: "Popup state pills"; options: ["filled", "outline", "minimal"]; value: root.statePillStyle; onChanged: function(value) { root.persistSettings({statePillStyle: value}) } }
        Dropdown { Layout.fillWidth: true; label: "Popup density"; options: ["comfortable", "compact"]; value: root.popupDensity; onChanged: function(value) { root.persistSettings({popupDensity: value}) } }
        Toggle { Layout.fillWidth: true; label: "Show state pills"; description: "Keep textual state visible beside each popup row."; checked: root.showStatePills; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({showStatePills: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Show session counts"; description: "Display a badge and bar count when several sessions share an item."; checked: root.showSessionCounts; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({showSessionCounts: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Animate verification"; description: "Pulse pending bar items until observed state confirms the action."; checked: root.animatePending; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({animatePending: !checked}) }
      }
    }
  }

  Component {
    id: alertsSettingsPage
    ColumnLayout {
      spacing: Style.spacing.md
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Notifications" }
        MultiSelect { Layout.fillWidth: true; label: "Activity notifications"; options: root.kindOptions; values: Model.arraySetting(root.setting("notificationKinds", ["microphone", "camera", "screen-share", "screen-recording", "location"]), []); foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { root.persistSettings({notificationKinds: values}) } }
        Toggle { Layout.fillWidth: true; label: "Activity started"; description: "Notify when selected privacy activity begins."; checked: root.setting("notifyOnActivity", true) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({notifyOnActivity: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Activity stopped"; description: "Notify when activity ends and include its duration."; checked: root.setting("notifyOnStop", false) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({notifyOnStop: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Control results"; description: "Notify when privacy control changes succeed or fail."; checked: root.setting("notifyOnControlChanges", true) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({notifyOnControlChanges: !checked}) }
        Text { Layout.fillWidth: true; text: "Applications without alerts (comma-separated exact names)"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: suppressedAppsEditor; Layout.fillWidth: true; text: Model.arraySetting(root.setting("notificationSuppressedApps", []), []).join(", "); placeholderText: "Firefox, OBS"; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistSettings({notificationSuppressedApps: root.commaList(text)}) }
          Button { text: "Save"; onClicked: root.persistSettings({notificationSuppressedApps: root.commaList(suppressedAppsEditor.text)}) }
        }
      }
    }
  }

  Component {
    id: monitoringSettingsPage
    ColumnLayout {
      spacing: Style.spacing.md
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Enhanced coverage" }
        MultiSelect { Layout.fillWidth: true; label: "Preventative controls"; options: root.kindOptions.filter(function(option) { return ["camera", "screen-share", "location"].indexOf(option.value) !== -1 }); values: Model.arraySetting(root.setting("blockableKinds", ["camera", "screen-share", "location"]), []); foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { root.persistSettings({blockableKinds: values}) } }
        Toggle { Layout.fillWidth: true; label: "Direct-device monitoring"; description: "Inspect same-user V4L2 and ALSA capture handles for applications that bypass PipeWire."; checked: root.setting("directDeviceMonitoring", false) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({directDeviceMonitoring: !checked}) }
        Toggle { Layout.fillWidth: true; label: "Show inferred attribution"; description: "Show heuristic application and device names; activity remains visible when disabled."; checked: root.setting("showInferredAttribution", true) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({showInferredAttribution: !checked}) }
        IntegerSetting { controller: root; settingKey: "directDevicePollSeconds"; label: "Direct-device heartbeat, seconds"; minimum: 2; maximum: 60; fallback: 5 }
      }
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Fallback polling" }
        IntegerSetting { controller: root; settingKey: "locationPollSeconds"; label: "Location refresh, seconds"; minimum: 5; maximum: 300; fallback: 15; stepSize: 5 }
        IntegerSetting { controller: root; settingKey: "recordingPollSeconds"; label: "Recorder refresh, seconds"; minimum: 1; maximum: 60; fallback: 2 }
        Text { Layout.fillWidth: true; text: "PipeWire activity remains event-backed. These intervals affect only enhanced and fallback observers."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      }
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Private data" }
        Toggle { Layout.fillWidth: true; label: "Keep recent activity"; description: "Store private metadata for seven days or 100 completed sessions."; checked: root.setting("historyEnabled", false) === true; foreground: Color.popups.text; accent: root.activeThemeColor; fontFamily: Style.font.family; onClicked: root.persistSettings({historyEnabled: !checked}) }
        Button { text: "Clear stored history"; enabled: privacyService !== null; onClicked: privacyService.clearHistory() }
        Text { Layout.fillWidth: true; text: "Export or restore a versioned settings file stored privately in your user data directory."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
        RowLayout {
          Layout.fillWidth: true
          Button { text: "Export settings"; enabled: !settingsTransferProc.running; onClicked: root.exportSettings() }
          Button { text: "Import settings"; enabled: !settingsTransferProc.running; onClicked: root.importSettings() }
          Item { Layout.fillWidth: true }
        }
        Text { visible: root.settingsTransferStatus !== ""; Layout.fillWidth: true; text: root.settingsTransferStatus; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      }
      SettingsSurface {
        accent: root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Status legend" }
        Text { Layout.fillWidth: true; text: "● Active    ⊘ Disabled    … Verifying    ! Degraded    Idle uses no marker"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
        Text { Layout.fillWidth: true; text: "Color, opacity, text, and markers reinforce each other so status never depends on color alone."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      }
      SettingsSurface {
        accent: root.monitoringDegraded ? Color.urgent : root.activeThemeColor
        PanelSectionHeader { Layout.fillWidth: true; text: "Observer health" }
        Text { Layout.fillWidth: true; text: root.monitoringTelemetryText(); textFormat: Text.PlainText; color: root.monitoringDegraded ? Color.urgent : Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
        Button { text: "Copy private diagnostics"; enabled: privacyService !== null; tooltipText: "Copy health and timing data with application and device names redacted"; onClicked: privacyService.copyDiagnostics(true) }
      }
    }
  }

  component GlobalSettingsTab: Button {
    required property string label
    required property string value
    Layout.fillWidth: true
    text: label
    active: root.globalSettingsPage === value
    selected: active
    bordered: true
    fontSize: Style.font.bodySmall
    horizontalPadding: Style.spacing.controlPaddingX
    verticalPadding: Style.spacing.controlPaddingY
    onClicked: { root.globalSettingsPage = value; contentFlick.contentY = 0 }
  }
}
