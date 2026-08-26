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
  readonly property var effectiveSettings: privacyService && privacyService.capturePreviewActive
    ? Object.assign({}, settings || {}, privacyService.capturePreviewSettings || {}) : settings
  readonly property var configuredOrder: Model.arraySetting(setting("order", []), Model.KINDS)
  readonly property bool showIdle: setting("showIdle", true) === true
  readonly property string displayMode: String(setting("displayMode", "icons"))
  readonly property bool showControls: setting("showControls", true) === true
  readonly property real idleOpacity: Math.max(0.1, Math.min(1, Number(setting("idleOpacity", 0.45))))
  readonly property real disabledOpacity: Math.max(0.25, Math.min(1, Number(setting("disabledOpacity", 1))))
  readonly property string statusMarkerMode: String(setting("statusMarkerMode", "symbols"))
  readonly property string barMarkerPosition: String(setting("barMarkerPosition", "after"))
  readonly property real barIconScale: Math.max(0.75, Math.min(1.5, Number(setting("barIconScale", 1))))
  readonly property int barItemSpacing: Math.max(0, Math.min(12, Number(setting("barItemSpacing", 0))))
  readonly property int barItemPadding: Math.max(2, Math.min(12, Number(setting("barItemPadding", 5))))
  readonly property string statePillStyle: String(setting("statePillStyle", "filled"))
  readonly property string popupDensity: String(setting("popupDensity", "comfortable"))
  readonly property string popupLayout: String(setting("popupLayout", "adaptive"))
  readonly property string popupWidth: String(setting("popupWidth", "standard"))
  readonly property real popupItemScale: Math.max(0.85, Math.min(1.3, Number(setting("popupItemScale", 1))))
  readonly property real popupIdleOpacity: Math.max(0.45, Math.min(1, Number(setting("popupIdleOpacity", 0.72))))
  readonly property int selectedPopupWidth: popupWidth === "narrow" ? 400 : (popupWidth === "wide" ? 720 : 460)
  readonly property int popupBaseWidth: popupLayout === "grid" ? Math.max(620, selectedPopupWidth) : selectedPopupWidth
  readonly property int popupGridColumns: popupLayout === "list" ? 1
    : (popup.width >= Style.space(600) && (popupLayout === "grid" || popupWidth === "wide") ? 2 : 1)
  readonly property bool showStatePills: setting("showStatePills", true) === true
  readonly property bool showSessionCounts: setting("showSessionCounts", true) === true
  readonly property bool showBarSessionCounts: setting("showBarSessionCounts", true) === true
  readonly property bool showBarActiveMarker: setting("showBarActiveMarker", true) === true
  readonly property bool showBarDisabledMarker: setting("showBarDisabledMarker", true) === true
  readonly property bool showBarPendingMarker: setting("showBarPendingMarker", true) === true
  readonly property bool showBarDegradedMarker: setting("showBarDegradedMarker", true) === true
  readonly property var customBarMarkers: ({
    active: String(setting("barActiveMarkerIcon", "●")),
    disabled: String(setting("barDisabledMarkerIcon", "⊘")),
    pending: String(setting("barPendingMarkerIcon", "…")),
    unavailable: String(setting("barDegradedMarkerIcon", "!")),
    idle: ""
  })
  readonly property bool animatePending: setting("animatePending", true) === true
  readonly property color activeThemeColor: themeColor(String(setting("activeColorRole", "bar-active")), true)
  readonly property color inactiveThemeColor: themeColor(String(setting("inactiveColorRole", "muted")), false)
  readonly property color disabledThemeColor: themeColor(String(setting("disabledColorRole", "urgent")), true)
  readonly property color mutedThemeColor: themeColor(String(setting("mutedColorRole", "urgent")), true)
  readonly property color unmutedThemeColor: themeColor(String(setting("unmutedColorRole", "foreground")), false)
  readonly property var activitySourceItems: orderedKinds().map(function(kind) { return item(kind) })
  readonly property var visibleItems: activitySourceItems.filter(function(entry) { return entry.active || itemShowsWhenIdle(entry.kind) })
  readonly property var activeItemList: visibleItems.filter(function(entry) { return entry.active })
  readonly property int activeCount: activeItemList.length
  readonly property bool monitoringDegraded: privacyService && typeof privacyService.monitoringDegraded === "function" ? privacyService.monitoringDegraded() : false
  readonly property var kindOptions: [
    {value: "microphone", label: "Microphone"}, {value: "audio-output", label: "Audio output"},
    {value: "camera", label: "Camera"}, {value: "screen-share", label: "Screen sharing"},
    {value: "screenshot", label: "Screenshot"}, {value: "screen-recording", label: "Screen recording"},
    {value: "location", label: "Location"}
  ]
  readonly property var deviceColorRoleOptions: [
    {value: "inherit", label: "Use global default"},
    {value: "bar-active", label: "Bar active"}, {value: "urgent", label: "Urgent"},
    {value: "accent", label: "Accent"}, {value: "foreground", label: "Foreground"},
    {value: "muted", label: "Muted"}
  ]
  readonly property var deviceVisibilityOptions: [
    {value: "inherit", label: "Use global default"},
    {value: "show", label: "Show"}, {value: "hide", label: "Hide"}
  ]
  readonly property var normalBarItems: displayMode === "active-count"
    ? [{kind: "summary", label: "Privacy", icon: activeCount > 0 ? "󰒃 " + activeCount : "󰒃", active: activeCount > 0, apps: [], controllable: false, controlEnabled: false, health: {status: "healthy"}, sessions: []}]
    : (displayMode === "active-only" ? activeItems() : visibleItems)
  readonly property var barItems: monitoringDegraded && normalBarItems.length === 0
    ? [{kind: "summary", label: "Privacy", icon: "󰀦", active: false, apps: [], controllable: false, controlEnabled: false, health: {status: "degraded"}, sessions: []}]
    : normalBarItems
  readonly property bool verticalBar: bar && bar.vertical === true
  readonly property int barFlowColumns: iconGrid.columns
  property string editingKind: ""
  property bool showingGlobalSettings: false
  property bool showingHistory: false
  property string historyQuery: ""
  property int historySummaryWindow: 24 * 60 * 60 * 1000
  property bool settingsMutationPending: false
  property string globalSettingsPage: "general"
  property string pendingSettingsSection: ""
  property string selectedKind: ""
  property var displayedActivityItems: []
  property var deferredActivityItems: null
  property int handledSettingsRequestSerial: 0
  property double durationNow: Date.now()
  readonly property string settingsTransferStatus: settingsTransferResult.status
  readonly property bool settingsTransferRunning: settingsTransferController.running
  readonly property bool settingsUndoAvailable: settingsTransferController.undoAvailable
  readonly property string settingsMutationMessage: settingsMutationController.status === "saving" ? "Saving changes…"
    : (settingsMutationController.status === "saved" ? "Changes applied"
    : (settingsMutationController.status === "failed" ? "Settings update failed" + (settingsMutationController.detail ? ": " + settingsMutationController.detail : "") : ""))
  readonly property bool settingsPageLoaded: globalSettingsPageLoader.item !== null
  readonly property var filteredHistory: Model.filterHistory(privacyService ? privacyService.displayHistory : [], historyQuery)
  readonly property var historySummaryRows: Model.historySummary(privacyService ? privacyService.displayHistory : [], durationNow, historySummaryWindow)
  readonly property var editingSessions: editingKind && privacyService ? privacyService.attributedSessionsFor(editingKind) : []
  readonly property var editingDevices: Model.unique(editingSessions.map(function(session) { return String(session.device || "") }).filter(Boolean))
  readonly property real openPanelIndicatorWidth: button.labelWidth

  function setting(key, fallback) {
    return effectiveSettings && effectiveSettings[key] !== undefined ? effectiveSettings[key] : fallback
  }

  function syncService() {
    if (privacyService && typeof privacyService.configure === "function") privacyService.configure(Model.sanitizeSettings(settings))
  }

  function syncDeviceEditors() {
    confirmationState.clear()
    if (!editingKind) return
    labelEditor.text = root.labelFor(editingKind)
    iconEditor.text = root.iconFor(editingKind)
    customScreenshotCommandEditor.text = String(root.setting("screenshotCustomCommand", ""))
    customScreenshotProcessEditor.text = String(root.setting("screenshotProcessName", ""))
    customRecorderProcessEditor.text = String(root.setting("recordingProcessName", ""))
    customRecorderStartEditor.text = String(root.setting("recordingCustomStartCommand", ""))
    customRecorderStopEditor.text = String(root.setting("recordingCustomStopCommand", ""))
  }

  function showGlobalSettings(page, section) {
    confirmationState.clear()
    var target = Model.settingsDeepLink(page, section)
    editingKind = ""
    showingHistory = false
    showingGlobalSettings = true
    globalSettingsPage = target.page
    pendingSettingsSection = target.section
    contentFlick.contentY = 0
    Qt.callLater(root.scrollToSettingsSection)
  }

  function scrollToSettingsSection() {
    if (!pendingSettingsSection || !globalSettingsPageLoader.item || !globalSettingsPageLoader.item.sectionItems) return
    var target = globalSettingsPageLoader.item.sectionItems[pendingSettingsSection]
    if (!target) { pendingSettingsSection = ""; return }
    var position = target.mapToItem(contentFlick.contentItem, 0, 0)
    contentFlick.contentY = Model.settingsScrollPosition(position.y, contentFlick.contentHeight, contentFlick.height)
    pendingSettingsSection = ""
  }

  function showActivity() {
    confirmationState.clear()
    editingKind = ""
    showingGlobalSettings = false
    showingHistory = false
    contentFlick.contentY = 0
  }

  function showHistory() {
    confirmationState.clear()
    editingKind = ""
    showingGlobalSettings = false
    showingHistory = true
    contentFlick.contentY = 0
    if (privacyService) privacyService.loadHistory()
  }

  function requestHistoryClear() {
    if (!confirmationState.request("history")) return
    if (privacyService) privacyService.clearHistory()
  }

  function handleSettingsRequest() {
    if (!opened || !privacyService || privacyService.settingsRequestSerial <= handledSettingsRequestSerial) return
    handledSettingsRequestSerial = privacyService.settingsRequestSerial
    if (privacyService.requestedView === "history") {
      historyQuery = privacyService.requestedViewArgument ? Model.label(privacyService.requestedViewArgument) : ""
      showHistory()
    } else if (privacyService.requestedView === "activity") {
      showActivity()
      editingKind = Model.KINDS.indexOf(privacyService.requestedViewArgument) >= 0 ? privacyService.requestedViewArgument : ""
    } else if (privacyService.requestedView === "lockdown") {
      showActivity()
      confirmationState.request("lockdown")
    } else if (privacyService.requestedView === "diagnostics") showGlobalSettings("monitoring", "observer-health")
    else showGlobalSettings(privacyService.requestedSettingsPage, privacyService.requestedSettingsSection)
  }

  function closeCurrentLayer() {
    var action = Model.popupDismissalAction(editingKind, showingGlobalSettings, showingHistory)
    if (action === "device") { editingKind = ""; return }
    if (action === "settings") { showActivity(); return }
    if (action === "history") { showActivity(); return }
    close()
  }

  function moveActivitySelection(delta) {
    var kinds = displayedActivityItems.map(function(entry) { return entry.kind })
    selectedKind = Model.nextNavigationKind(kinds, selectedKind, delta)
  }

  function activateActivitySelection() {
    var kinds = displayedActivityItems.map(function(entry) { return entry.kind })
    var target = Model.activationKind(kinds, selectedKind)
    selectedKind = target
    if (target) { showingGlobalSettings = false; showingHistory = false; editingKind = target; contentFlick.contentY = 0 }
  }

  function moveDeviceEditor(delta) {
    var order = orderedKinds()
    var target = Model.nextNavigationKind(order, editingKind, delta)
    if (!target || target === editingKind) return
    editingKind = target
    selectedKind = editingKind
    contentFlick.contentY = 0
  }

  function syncDisplayedItems() {
    var next = activitySourceItems
    // Never defer privacy state changes; only defer non-critical text/session churn.
    if (contentFlick.moving && Model.activityCriticalStateEquivalent(displayedActivityItems, next)) deferredActivityItems = next
    else { displayedActivityItems = next; deferredActivityItems = null }
  }

  function flushDeferredItems() {
    if (deferredActivityItems !== null) {
      displayedActivityItems = deferredActivityItems
      deferredActivityItems = null
    }
  }

  function monitoringTelemetryText() {
    var data = privacyService && typeof privacyService.monitoringTelemetry === "function"
      ? privacyService.monitoringTelemetry() : null
    return Model.monitoringTelemetryText(data)
  }

  function commaList(value) {
    return Model.unique(String(value || "").split(",").map(function(entry) { return entry.trim() }).filter(Boolean))
  }

  function deviceLabel(device) {
    return Model.deviceLabel(device, setting("deviceLabels", {}))
  }

  function persistDeviceLabel(device, value) {
    var labels = Object.assign({}, setting("deviceLabels", {}) || {})
    var key = String(device || "")
    var text = String(value || "").trim()
    if (!key) return
    if (text && text !== key) labels[key] = text
    else delete labels[key]
    persistSettings({deviceLabels: labels})
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
    if (role === "foreground") return bar ? bar.foreground : Color.foreground
    if (role === "muted") return Color.muted
    return activeFallback ? Color.bar.active : Color.muted
  }

  function deviceDiagnostic(kind) {
    if (!privacyService || typeof privacyService.diagnostic !== "function") return {
      healthStatus: "unavailable", dependenciesReady: true, dependencyDescription: "",
      rows: [{label: "Status", value: "Diagnostics unavailable", urgent: true}]
    }
    return Model.deviceDiagnosticPresentation(privacyService.diagnostic(kind))
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
    var state = itemVisualState(entry)
    var stateVisible = state === "active" ? showBarActiveMarker
      : (state === "disabled" ? showBarDisabledMarker
      : (state === "pending" ? showBarPendingMarker
      : (state === "unavailable" ? showBarDegradedMarker : true)))
    return Model.privacyStateMarker(entry, statusMarkerMode, itemStatusMarkerVisible(entry.kind) && stateVisible, customBarMarkers)
  }
  function itemSessionCount(entry) { return Model.privacySessionCount(entry, showSessionCounts) }

  function barItemText(entry) {
    var marker = itemStateMarker(entry)
    var count = Model.privacySessionCount(entry, showBarSessionCounts)
    var text = entry.icon
    if (marker) text = barMarkerPosition === "before" ? marker + " " + text : text + " " + marker
    return text + (count ? " " + String(count) : "")
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
    settingsMutationController.submit(effectiveSettings, values)
  }

  function commitSettings(candidate) {
    var previous = settings
    var clean = Model.sanitizeSettings(candidate)
    var entry = {id: moduleName}
    for (var sanitizedKey in clean) entry[sanitizedKey] = clean[sanitizedKey]
    settings = entry
    syncService()
    settingsMutationPending = true
    settingsMutationGuard.restart()
    try {
      if (!bar || !bar.shell || typeof bar.shell.updateEntryInline !== "function") throw new Error("shell settings API unavailable")
      bar.shell.updateEntryInline(moduleName, entry)
      settingsMutationController.complete(true)
      Qt.callLater(function() { if (!root.opened) root.open() })
    } catch (error) {
      settings = previous
      syncService()
      settingsMutationController.complete(false, String(error && error.message ? error.message : error))
    }
  }

  function settingsHelperPath() {
    return String(Qt.resolvedUrl("privacy-settings")).replace(/^file:\/\//, "")
  }

  function exportSettings() {
    settingsTransferResult.begin("Exporting…")
    if (!settingsTransferController.request("export", Model.sanitizeSettings(effectiveSettings))) settingsTransferResult.begin("Transfer busy")
  }

  function importSettings() {
    settingsTransferResult.begin("Importing…")
    if (!settingsTransferController.request("import", Model.sanitizeSettings(effectiveSettings))) settingsTransferResult.begin("Transfer busy")
  }

  function undoSettingsChange() {
    settingsTransferResult.begin("Restoring…")
    if (!settingsTransferController.request("undo", {})) settingsTransferResult.begin("Transfer busy")
  }

  function requestGlobalSettingsReset() {
    settingsTransferResult.begin("Saving undo point…")
    if (!settingsTransferController.request("checkpoint", Model.sanitizeSettings(effectiveSettings))) settingsTransferResult.begin("Transfer busy")
  }

  function handleSettingsTransfer(mode, payload) {
    settingsTransferResult.apply(mode, payload)
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
      barIconScale: 1,
      barItemSpacing: 0,
      barItemPadding: 5,
      barMarkerPosition: "after",
      showBarSessionCounts: true,
      showBarActiveMarker: true,
      showBarDisabledMarker: true,
      showBarPendingMarker: true,
      showBarDegradedMarker: true,
      barActiveMarkerIcon: "●",
      barDisabledMarkerIcon: "⊘",
      barPendingMarkerIcon: "…",
      barDegradedMarkerIcon: "!",
      showControls: true,
      idleOpacity: 0.45,
      disabledOpacity: 1,
      statusMarkerMode: "symbols",
      statePillStyle: "filled",
      popupDensity: "comfortable",
      popupLayout: "adaptive",
      popupWidth: "standard",
      popupItemScale: 1,
      popupIdleOpacity: 0.72,
      showStatePills: true,
      showSessionCounts: true,
      animatePending: true,
      deduplicateApps: true,
      notifyOnActivity: true,
      notifyOnStop: false,
      notifyOnControlChanges: true,
      notifyOnObserverHealth: false,
      historyEnabled: false,
      hiddenApps: [],
      notificationSuppressedApps: [],
      hiddenDevices: [],
      notificationSuppressedDevices: [],
      deviceLabels: {},
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
    Qt.callLater(function() { if (root.editingKind === kind) iconEditor.text = root.iconFor(kind) })
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
    Qt.callLater(function() { if (root.editingKind === kind) labelEditor.text = root.labelFor(kind) })
  }

  function persistItemColor(kind, state, role) {
    var roles = JSON.parse(JSON.stringify(setting("itemColorRoles", {}) || {}))
    if (role === "inherit") {
      if (roles[kind]) {
        delete roles[kind][state]
        if (Object.keys(roles[kind]).length === 0) delete roles[kind]
      }
    } else {
      if (!roles[kind]) roles[kind] = {}
      roles[kind][state] = role
    }
    persistSettings({itemColorRoles: roles})
  }

  function persistItemStatusMarker(kind, mode) {
    var visibility = JSON.parse(JSON.stringify(setting("itemStatusMarkerVisibility", {}) || {}))
    if (mode === "inherit") delete visibility[kind]
    else visibility[kind] = mode === "show"
    persistSettings({itemStatusMarkerVisibility: visibility})
  }

  function itemColorRole(kind, state, fallback) {
    var roles = setting("itemColorRoles", {}) || {}
    return roles[kind] && roles[kind][state] ? String(roles[kind][state]) : fallback
  }

  function itemColorOverrideRole(kind, state) {
    return Model.hasItemOverride(effectiveSettings, "itemColorRoles", kind, state)
      ? String(setting("itemColorRoles", {})[kind][state]) : "inherit"
  }

  function itemOverrideMode(group, kind) {
    return Model.itemOverrideMode(effectiveSettings, group, kind)
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

  function canMoveItem(kind, delta) {
    var order = orderedKinds()
    var index = order.indexOf(kind)
    return index >= 0 && index + delta >= 0 && index + delta < order.length
  }

  function itemShowsWhenIdle(kind) {
    var overrides = setting("itemIdleVisibility", {}) || {}
    return overrides[kind] !== undefined ? overrides[kind] === true : showIdle
  }

  function persistItemIdleVisibility(kind, mode) {
    var overrides = JSON.parse(JSON.stringify(setting("itemIdleVisibility", {}) || {}))
    if (mode === "inherit") delete overrides[kind]
    else overrides[kind] = mode === "show"
    persistSettings({itemIdleVisibility: overrides})
  }

  function itemIdleOpacity(kind) {
    var overrides = setting("itemIdleOpacity", {}) || {}
    var value = overrides[kind] !== undefined ? Number(overrides[kind]) : idleOpacity
    return Math.max(0.1, Math.min(1, isFinite(value) ? value : idleOpacity))
  }

  function persistItemIdleOpacity(kind, percent) {
    var overrides = JSON.parse(JSON.stringify(setting("itemIdleOpacity", {}) || {}))
    if (percent === null || percent === undefined) delete overrides[kind]
    else overrides[kind] = Math.max(10, Math.min(100, Number(percent))) / 100
    persistSettings({itemIdleOpacity: overrides})
  }

  function itemResetValues(kind) {
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
    return {icons: icons, itemColorRoles: roles, itemIdleVisibility: visibility, itemIdleOpacity: opacity, itemStatusMarkerVisibility: markerVisibility, itemLabels: labels}
  }

  function resetItemSettings(kind) {
    persistSettings(itemResetValues(kind))
    Qt.callLater(syncDeviceEditors)
  }

  function deviceBackendDefaults(kind) {
    if (kind === "screenshot") return {screenshotBackend: "omarchy", screenshotCustomCommand: "", screenshotProcessName: ""}
    if (kind === "screen-recording") return {recordingBackend: "omarchy", recordingProcessName: "", recordingCustomStartCommand: "", recordingCustomStopCommand: ""}
    if (isAudioControl({kind: kind})) return {audioControlBackend: "auto"}
    return {}
  }

  function resetDeviceBackend(kind) {
    persistSettings(deviceBackendDefaults(kind))
    Qt.callLater(syncDeviceEditors)
  }

  function resetAllDeviceSettings(kind) {
    var values = itemResetValues(kind)
    var backend = deviceBackendDefaults(kind)
    for (var key in backend) values[key] = backend[key]
    persistSettings(values)
    Qt.callLater(syncDeviceEditors)
  }

  function toggleEntry(entry) {
    if (!privacyService || !entry.controllable || entry.pending) return
    if (!entry.dependenciesReady) {
      privacyService.installDependencies(entry.kind)
      return
    }
    if (entry.kind === "screen-recording") {
      if (!privacyService.beginExternalControl("screen-recording", !entry.controlEnabled)) return
      var backend = String(setting("recordingBackend", "omarchy"))
      if (backend === "wf-recorder") {
        var recordingHelper = privacyService.dependencyHelperPath().replace("privacy-deps", "privacy-recording")
        Quickshell.execDetached([recordingHelper, entry.controlEnabled ? "stop" : "start", "wf-recorder"])
      }
      else if (backend === "custom") {
        var command = String(setting(entry.controlEnabled ? "recordingCustomStopCommand" : "recordingCustomStartCommand", ""))
        if (command) bar.run(command)
      }
      else if (entry.controlEnabled) Quickshell.execDetached(["omarchy-capture-screenrecording", "--stop-recording"])
      else Quickshell.execDetached(["omarchy-menu", "toggle", "trigger.capture.screenrecord"])
      return
    }
    if (entry.kind === "screenshot") {
      var screenshotBackend = String(setting("screenshotBackend", "omarchy"))
      if (screenshotBackend === "custom") {
        var screenshotCommand = String(setting("screenshotCustomCommand", ""))
        if (screenshotCommand) bar.run(screenshotCommand)
      }
      else if (screenshotBackend === "omarchy") Quickshell.execDetached(["omarchy-capture-screenshot"])
      else {
        var screenshotHelper = privacyService.dependencyHelperPath().replace("privacy-deps", "privacy-screenshot")
        Quickshell.execDetached([screenshotHelper, "capture", screenshotBackend])
      }
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

  function activeItems() {
    return activeItemList
  }

  function iconFor(kind) {
    var icons = setting("icons", {}) || {}
    return icons[kind] !== undefined ? String(icons[kind]) : defaultIcon(kind)
  }

  function defaultIcon(kind) {
    var defaults = {"microphone":"󰍬", "audio-output":"󰓃", "camera":"󰄀", "screen-share":"󰍹", "screenshot":"󰹑", "screen-recording":"󰻂", "location":"󰋽"}
    return String(defaults[kind] || "")
  }

  function deviceAppearanceCustomized(kind) {
    var labels = setting("itemLabels", {}) || {}
    var icons = setting("icons", {}) || {}
    return Object.prototype.hasOwnProperty.call(labels, kind)
      || (Object.prototype.hasOwnProperty.call(icons, kind) && String(icons[kind]) !== defaultIcon(kind))
      || Model.hasItemOverride(effectiveSettings, "itemColorRoles", kind)
      || Model.hasItemOverride(effectiveSettings, "itemIdleVisibility", kind)
      || Model.hasItemOverride(effectiveSettings, "itemIdleOpacity", kind)
      || Model.hasItemOverride(effectiveSettings, "itemStatusMarkerVisibility", kind)
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
    var action = Model.itemTooltipAction(entry)
    return label + " · " + state
      + "\n" + action
      + "\nMiddle click for " + label.toLowerCase() + " settings"
      + "\nRight click for privacy details"
  }

  function pressItem(entry, buttonCode) {
    if (buttonCode === Qt.MiddleButton) {
      if (entry.kind === "summary") showGlobalSettings("general")
      else { showingGlobalSettings = false; showingHistory = false; editingKind = entry.kind }
      root.open()
      return
    }
    if (buttonCode === Qt.RightButton || entry.kind === "summary" || !entry.controllable) {
      editingKind = ""
      showingGlobalSettings = false
      showingHistory = false
      root.toggle()
      return
    }
    root.toggleEntry(entry)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  visible: root.barItems.length > 0

  onSettingsChanged: Qt.callLater(syncService)
  onEditingKindChanged: {
    Qt.callLater(syncDeviceEditors)
    if (privacyService && isAudioControl({kind: editingKind})) privacyService.refreshAudioEndpoints(editingKind)
  }
  onPrivacyServiceChanged: Qt.callLater(syncService)
  onActivitySourceItemsChanged: syncDisplayedItems()
  onOpenedChanged: {
    if (opened) {
      durationNow = Date.now()
      handleSettingsRequest()
    }
    else if (settingsMutationPending) Qt.callLater(root.open)
    else {
      editingKind = ""
      showingGlobalSettings = false
      showingHistory = false
      globalSettingsPage = "general"
      contentFlick.contentY = 0
    }
  }
  Connections {
    target: root.privacyService
    function onSettingsRequestSerialChanged() { root.handleSettingsRequest() }
  }
  Component.onCompleted: { syncDisplayedItems(); Qt.callLater(syncService) }

  Timer {
    id: settingsMutationGuard
    interval: 2000
    onTriggered: root.settingsMutationPending = false
  }

  PrivacyConfirmationController { id: confirmationState }
  PrivacySettingsMutationController {
    id: settingsMutationController
    onCommitRequested: function(settings) { root.commitSettings(settings) }
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
    implicitWidth: root.verticalBar && root.bar ? root.bar.barSize : iconGrid.implicitWidth
    implicitHeight: root.verticalBar ? iconGrid.implicitHeight : (root.bar ? root.bar.barSize : Style.bar.sizeHorizontal)
    property real labelWidth: implicitWidth

    Grid {
      id: iconGrid
      anchors.centerIn: parent
      columns: root.verticalBar ? 1 : Math.max(1, root.barItems.length)
      spacing: root.barItemSpacing

      Repeater {
        model: root.barItems
        delegate: WidgetButton {
          required property var modelData
          bar: root.bar
          text: root.sharedText(root.barItemText(modelData))
          fontSize: Style.font.body * root.barIconScale
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
          horizontalMargin: modelData.kind === "summary" ? root.barItemPadding + 3.5 : root.barItemPadding
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
    contentWidth: fittedContentWidth(Style.space(root.popupBaseWidth))
    contentHeight: fittedContentHeight(content.implicitHeight, Style.space(Math.max(360, Math.min(900, Number(root.setting("popupMaxHeight", 620)) || 620))))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.closeCurrentLayer()
      onMoveRequested: function(dx, dy) {
        if (root.editingKind !== "" && dx !== 0) root.moveDeviceEditor(dx)
        else if (dy !== 0 && root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory) root.moveActivitySelection(dy)
      }
      onActivateRequested: {
        if (root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory) root.activateActivitySelection()
      }
      onTextKey: function(text) {
        if ((text === "h" || text === "H") && root.editingKind === "") root.showHistory()
        else if ((text === "s" || text === "S") && root.editingKind === "") root.showGlobalSettings("general")
        else if ((text === "r" || text === "R") && !root.showingGlobalSettings && !root.showingHistory && privacyService) privacyService.refreshFallbacks()
        else if (root.showingGlobalSettings && "1234".indexOf(text) >= 0) {
          root.showGlobalSettings(["general", "appearance", "alerts", "monitoring"][Number(text) - 1], "")
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
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory
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
            border.width: 1
            border.color: Util.alpha(root.monitoringDegraded ? Color.urgent : (root.activeCount > 0 ? root.activeThemeColor : root.inactiveThemeColor), 0.32)
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
            iconText: "󰋚"
            tooltipText: "Activity history"
            horizontalPadding: Style.spacing.controlGap
            onClicked: root.showHistory()
          }
          Button {
            iconText: privacyService && privacyService.privacyPresetUndoAvailable ? "󰌿" : "󰌾"
            enabled: privacyService && privacyService.privacyPresetState !== "applying" && privacyService.privacyPresetState !== "restoring"
            tooltipText: privacyService && privacyService.privacyPresetUndoAvailable
              ? "Restore the privacy state from before lockdown"
              : (confirmationState.pending === "lockdown" ? "Confirm privacy lockdown" : "Lock down privacy controls")
            horizontalPadding: Style.spacing.controlGap
            onClicked: {
              if (privacyService.privacyPresetUndoAvailable) {
                privacyService.restorePrivacyLockdown()
                confirmationState.clear()
                return
              }
              if (!confirmationState.request("lockdown")) return
              privacyService.requestPrivacyLockdown()
              confirmationState.clear()
            }
          }
          Button {
            iconText: "󰒓"
            tooltipText: "Global settings"
            horizontalPadding: Style.spacing.controlGap
            onClicked: root.showGlobalSettings("general")
          }
        }

        RowLayout {
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory && privacyService && privacyService.privacyPresetMessage() !== ""
          Layout.fillWidth: true
          PrivacyMessageSurface {
            Layout.fillWidth: true
            message: privacyService ? privacyService.privacyPresetMessage() : ""
            kind: privacyService && privacyService.privacyPresetState === "partial" ? "error" : "info"
          }
        }

        ColumnLayout {
          id: historyView
          visible: root.showingHistory
          Layout.fillWidth: true
          spacing: Style.spacing.md

          RowLayout {
            Layout.fillWidth: true
            Button { iconText: "󰁍"; tooltipText: "Back"; horizontalPadding: Style.spacing.controlGap; onClicked: root.showActivity() }
            Text { Layout.fillWidth: true; text: "Activity history"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.title; font.weight: Font.DemiBold }
            Button {
              visible: root.setting("historyEnabled", false) === true && privacyService && privacyService.displayHistory.length > 0
              text: confirmationState.pending === "history" ? "Confirm clear" : "Clear history"
              onClicked: root.requestHistoryClear()
            }
          }

          SettingsSurface {
            visible: root.setting("historyEnabled", false) === true && root.historySummaryRows.length > 0
            Layout.fillWidth: true
            PanelSectionHeader { Layout.fillWidth: true; text: "Privacy summary" }
            RowLayout {
              Layout.fillWidth: true
              Button { text: "Today"; enabled: root.historySummaryWindow !== 24 * 60 * 60 * 1000; onClicked: root.historySummaryWindow = 24 * 60 * 60 * 1000 }
              Button { text: "7 days"; enabled: root.historySummaryWindow !== 7 * 24 * 60 * 60 * 1000; onClicked: root.historySummaryWindow = 7 * 24 * 60 * 60 * 1000 }
              Item { Layout.fillWidth: true }
            }
            Repeater {
              model: root.historySummaryRows
              delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { text: root.iconFor(modelData.kind); textFormat: Text.PlainText; color: root.itemColor(root.item(modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.icon * root.popupItemScale }
                ColumnLayout {
                  Layout.fillWidth: true
                  Text { Layout.fillWidth: true; text: Model.label(modelData.kind) + " · " + modelData.count + (modelData.count === 1 ? " session" : " sessions") + " · " + Model.formatDuration(modelData.durationMs); textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body * root.popupItemScale; elide: Text.ElideRight }
                  Text { Layout.fillWidth: true; text: modelData.applications.join(", "); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption * root.popupItemScale; elide: Text.ElideRight }
                  Text { visible: modelData.newApplications.length > 0; Layout.fillWidth: true; text: "New in retained history: " + modelData.newApplications.join(", "); textFormat: Text.PlainText; color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.caption * root.popupItemScale; elide: Text.ElideRight }
                }
              }
            }
          }

          RowLayout {
            visible: root.setting("historyEnabled", false) === true && privacyService && privacyService.displayHistory.length > 0
            Layout.fillWidth: true
            TextField {
              id: historySearch
              Layout.fillWidth: true
              placeholderText: "Search history"
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onTextChanged: root.historyQuery = text
            }
            Rectangle {
              id: historyCountPill
              implicitWidth: historyCountText.implicitWidth + Style.spacing.md * 2
              implicitHeight: historyCountText.implicitHeight + Style.spacing.sm
              radius: implicitHeight / 2
              color: Util.alpha(root.activeThemeColor, 0.14)
              border.width: 1
              border.color: Util.alpha(root.activeThemeColor, 0.28)
              Text {
                id: historyCountText
                anchors.centerIn: parent
                text: Model.historyCountLabel(root.filteredHistory.length, privacyService.displayHistory.length)
                textFormat: Text.PlainText
                color: root.activeThemeColor
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.weight: Font.DemiBold
              }
            }
          }

          SettingsSurface {
            visible: root.setting("historyEnabled", false) !== true
            Layout.fillWidth: true
            PanelSectionHeader { Layout.fillWidth: true; text: "History is off" }
            Text { Layout.fillWidth: true; text: "Enable history to keep completed activity on this device for up to seven days."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
            Button { text: "Open monitoring settings"; onClicked: root.showGlobalSettings("monitoring", "private-data") }
          }

          PrivacyMessageSurface {
            visible: root.setting("historyEnabled", false) === true && privacyService && !privacyService.historyLoaded
            message: "Loading history…"
          }

          PrivacyMessageSurface {
            visible: root.setting("historyEnabled", false) === true && privacyService && privacyService.historyLoaded && privacyService.displayHistory.length === 0
            message: "No completed activity yet."
          }

          PrivacyMessageSurface {
            visible: root.setting("historyEnabled", false) === true && privacyService && privacyService.displayHistory.length > 0 && root.filteredHistory.length === 0
            message: "No history matches your search."
          }

          GridLayout {
            id: historyRows
            Layout.fillWidth: true
            columns: root.popupGridColumns
            columnSpacing: root.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
            rowSpacing: root.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
            Repeater {
              model: root.filteredHistory
              delegate: SettingsSurface {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.columnSpan: root.popupGridColumns === 2 && index === root.filteredHistory.length - 1 && root.filteredHistory.length % 2 === 1 ? 2 : 1
                accent: root.itemColor(root.item(modelData.kind))
                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.spacing.md * root.popupItemScale
                  Text { text: root.iconFor(modelData.kind); textFormat: Text.PlainText; color: root.itemColor(root.item(modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.icon * root.popupItemScale }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.spacing.xs
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.spacing.sm
                      Text { Layout.fillWidth: true; text: modelData.application || "Unknown application"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body * root.popupItemScale; font.weight: Font.DemiBold; elide: Text.ElideRight }
                      Text { text: Model.historyPeriodLabel(modelData.endedAt, root.durationNow); textFormat: Text.PlainText; color: root.itemColor(root.item(modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.caption * root.popupItemScale; font.weight: Font.DemiBold }
                    }
                    Text { Layout.fillWidth: true; text: Model.label(modelData.kind) + " · " + Model.formatDuration(modelData.durationMs) + " · " + Model.historyAgeLabel(modelData.endedAt, root.durationNow) + (modelData.confidence && String(modelData.confidence).toLowerCase() !== "confirmed" ? " · Inferred" : ""); textFormat: Text.PlainText; color: Color.muted; opacity: Math.max(0.75, root.popupIdleOpacity); font.family: Style.font.family; font.pixelSize: Style.font.caption * root.popupItemScale; elide: Text.ElideRight }
                    Text { visible: root.popupDensity !== "compact" && Boolean(modelData.device); Layout.fillWidth: true; text: root.deviceLabel(modelData.device); textFormat: Text.PlainText; color: Color.muted; opacity: Math.max(0.75, root.popupIdleOpacity); font.family: Style.font.family; font.pixelSize: Style.font.caption * root.popupItemScale; elide: Text.ElideRight }
                  }
                }
              }
            }
          }
        }

        ColumnLayout {
          id: globalSettingsEditor
          visible: root.showingGlobalSettings
          Layout.fillWidth: true
          spacing: Style.spacing.md

          PrivacySettingsNavigation { controller: root }

          PrivacyMessageSurface {
            visible: root.settingsMutationMessage !== ""
            message: root.settingsMutationMessage
            kind: settingsMutationController.status === "failed" ? "error" : (settingsMutationController.status === "saved" ? "success" : "info")
          }

          Loader {
            id: globalSettingsPageLoader
            Layout.fillWidth: true
            sourceComponent: root.globalSettingsPage === "general" ? generalSettingsPage
              : (root.globalSettingsPage === "appearance" ? appearanceSettingsPage
              : (root.globalSettingsPage === "alerts" ? alertsSettingsPage : monitoringSettingsPage))
            onLoaded: Qt.callLater(root.scrollToSettingsSection)
          }

          Button { Layout.alignment: Qt.AlignRight; text: "Reset global settings"; enabled: !root.settingsTransferRunning; onClicked: root.requestGlobalSettingsReset() }
        }

        DeviceSettingsEditor {
          visible: root.editingKind !== "" && !root.showingGlobalSettings && !root.showingHistory
          controller: root
          onBackRequested: root.editingKind = ""

          PrivacyMessageSurface {
            visible: root.settingsMutationMessage !== ""
            message: root.settingsMutationMessage
            kind: settingsMutationController.status === "failed" ? "error" : (settingsMutationController.status === "saved" ? "success" : "info")
          }

          SettingsSurface {
            Layout.fillWidth: true
            accent: root.itemColor(root.item(root.editingKind))
            PanelSectionHeader { Layout.fillWidth: true; text: "Bar preview" }
            RowLayout {
              id: previewRow
              Layout.fillWidth: true
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

          AudioEndpointSettings {
            visible: root.isAudioControl({kind: root.editingKind})
            controller: root
          }

          SettingsSurface {
            id: appearanceSurface
            accent: root.activeThemeColor
            property bool labelDirty: labelEditor.text.trim() !== root.labelFor(root.editingKind)
            property bool iconDirty: iconEditor.text !== root.iconFor(root.editingKind)
            PanelSectionHeader { Layout.fillWidth: true; text: "Appearance" }
            Text {
              Layout.fillWidth: true
              text: appearanceSurface.labelDirty || appearanceSurface.iconDirty ? "Unsaved changes" : (root.deviceAppearanceCustomized(root.editingKind) ? "Customized" : "Using global defaults")
              textFormat: Text.PlainText
              color: appearanceSurface.labelDirty || appearanceSurface.iconDirty ? Color.accent : Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
            GridLayout {
              Layout.fillWidth: true
              columns: root.popupWidth === "wide" ? 2 : 1
              columnSpacing: Style.spacing.md
              rowSpacing: Style.spacing.md
              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.xs
                Text { Layout.fillWidth: true; text: "Display label"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
                RowLayout {
                  Layout.fillWidth: true
                  TextField { id: labelEditor; Layout.fillWidth: true; placeholderText: "Display label"; text: root.editingKind ? root.labelFor(root.editingKind) : ""; maximumLength: 128; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistLabel(root.editingKind, text) }
                  Button { text: "Save"; tooltipText: "Save display label"; enabled: appearanceSurface.labelDirty; onClicked: root.persistLabel(root.editingKind, labelEditor.text) }
                }
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.spacing.xs
                Text { Layout.fillWidth: true; text: "Device icon"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
                RowLayout {
                  Layout.fillWidth: true
                  TextField { id: iconEditor; Layout.fillWidth: true; placeholderText: "Icon"; text: root.editingKind ? root.iconFor(root.editingKind) : ""; maximumLength: 8; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistIcon(root.editingKind, text) }
                  Button { text: "Save"; tooltipText: "Save device icon"; enabled: appearanceSurface.iconDirty; onClicked: root.persistIcon(root.editingKind, iconEditor.text) }
                }
              }
            }

            GridLayout {
              Layout.fillWidth: true
              columns: root.popupWidth === "wide" ? 2 : 1
              columnSpacing: Style.spacing.md
              rowSpacing: Style.spacing.md
              Dropdown {
                Layout.fillWidth: true
                label: root.isAudioControl({kind: root.editingKind}) ? "Muted color" : "Active color"
                options: root.deviceColorRoleOptions
                value: root.itemColorOverrideRole(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "muted" : "active")
                onChanged: function(value) { root.persistItemColor(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "muted" : "active", value) }
              }
              Dropdown {
                Layout.fillWidth: true
                label: root.isAudioControl({kind: root.editingKind}) ? "Unmuted color" : "Inactive color"
                options: root.deviceColorRoleOptions
                value: root.itemColorOverrideRole(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "unmuted" : "inactive")
                onChanged: function(value) { root.persistItemColor(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "unmuted" : "inactive", value) }
              }
              Dropdown {
                visible: root.isPreventativeControl({kind: root.editingKind})
                Layout.fillWidth: true
                Layout.columnSpan: root.popupWidth === "wide" ? 2 : 1
                label: "Disabled color"
                options: root.deviceColorRoleOptions
                value: root.itemColorOverrideRole(root.editingKind, "disabled")
                onChanged: function(value) { root.persistItemColor(root.editingKind, "disabled", value) }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              NumberField {
                Layout.fillWidth: true
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
              Button {
                text: "Use default"
                enabled: Model.hasItemOverride(root.effectiveSettings, "itemIdleOpacity", root.editingKind)
                onClicked: root.persistItemIdleOpacity(root.editingKind, null)
              }
            }

            Dropdown {
              Layout.fillWidth: true
              label: "Show status markers for this device"
              options: root.deviceVisibilityOptions
              value: root.itemOverrideMode("itemStatusMarkerVisibility", root.editingKind)
              onChanged: function(value) { root.persistItemStatusMarker(root.editingKind, value) }
            }
            RowLayout {
              Layout.fillWidth: true
              Text { Layout.fillWidth: true; text: "Global status-marker rules still apply when this device is set to show."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
              Button { text: "Global marker settings"; onClicked: root.showGlobalSettings("appearance", "status-presentation") }
            }
          }

          SettingsSurface {
            accent: root.activeThemeColor
            PanelSectionHeader { Layout.fillWidth: true; text: "Bar placement" }
            RowLayout {
              Layout.fillWidth: true
              Button {
                text: "Move left"
                enabled: root.canMoveItem(root.editingKind, -1)
                onClicked: root.moveItem(root.editingKind, -1)
              }
              Button {
                text: "Move right"
                enabled: root.canMoveItem(root.editingKind, 1)
                onClicked: root.moveItem(root.editingKind, 1)
              }
              Item { Layout.fillWidth: true }
            }
            Dropdown {
              Layout.fillWidth: true
              label: "Show while idle"
              options: root.deviceVisibilityOptions
              value: root.itemOverrideMode("itemIdleVisibility", root.editingKind)
              onChanged: function(value) { root.persistItemIdleVisibility(root.editingKind, value) }
            }
          }

          SettingsSurface {
            visible: root.editingDevices.length > 0
            Layout.fillWidth: true
            accent: root.activeThemeColor
            PanelSectionHeader { Layout.fillWidth: true; text: "Detected hardware" }
            Repeater {
              model: root.editingDevices
              delegate: ColumnLayout {
                required property string modelData
                Layout.fillWidth: true
                spacing: Style.spacing.xs
                Text { Layout.fillWidth: true; text: modelData; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideMiddle }
                RowLayout {
                  Layout.fillWidth: true
                  TextField { id: deviceLabelEditor; Layout.fillWidth: true; text: root.deviceLabel(modelData); placeholderText: "Friendly device name"; maximumLength: 128; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistDeviceLabel(modelData, text) }
                  Button { text: "Save name"; enabled: deviceLabelEditor.text.trim() !== root.deviceLabel(modelData); onClicked: root.persistDeviceLabel(modelData, deviceLabelEditor.text) }
                }
              }
            }
          }

          SettingsSurface {
            visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind})
            Layout.fillWidth: true
            accent: root.activeThemeColor
            PanelSectionHeader { Layout.fillWidth: true; text: "Backend" }

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
            property bool dirty: customScreenshotCommandEditor.text !== String(root.setting("screenshotCustomCommand", ""))
              || customScreenshotProcessEditor.text !== String(root.setting("screenshotProcessName", ""))
            property var validation: Model.deviceBackendValidation("screenshot", {
              screenshotBackend: "custom",
              screenshotCustomCommand: customScreenshotCommandEditor.text,
              screenshotProcessName: customScreenshotProcessEditor.text
            })
            Text { Layout.fillWidth: true; text: "Screenshot command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
            TextField {
              id: customScreenshotCommandEditor
              Layout.fillWidth: true
              placeholderText: "Screenshot command"
              text: String(root.setting("screenshotCustomCommand", ""))
              maximumLength: 4096
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: if (parent.validation.valid) root.persistSettings({screenshotCustomCommand: text, screenshotProcessName: customScreenshotProcessEditor.text})
            }
            Text { Layout.fillWidth: true; text: "Activity process substring (optional)"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
            TextField {
              id: customScreenshotProcessEditor
              Layout.fillWidth: true
              placeholderText: "Activity process substring (optional)"
              text: String(root.setting("screenshotProcessName", ""))
              maximumLength: 256
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: if (parent.validation.valid) root.persistSettings({screenshotCustomCommand: customScreenshotCommandEditor.text, screenshotProcessName: text})
            }
            Text {
              Layout.fillWidth: true
              text: !parent.validation.valid ? parent.validation.message : (parent.dirty ? "Unsaved changes" : "Saved")
              textFormat: Text.PlainText
              color: !parent.validation.valid ? Color.urgent : (parent.dirty ? Color.accent : Color.muted)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
            Button {
              text: "Save custom backend"
              enabled: parent.dirty && parent.validation.valid
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
            property bool dirty: customRecorderProcessEditor.text !== String(root.setting("recordingProcessName", ""))
              || customRecorderStartEditor.text !== String(root.setting("recordingCustomStartCommand", ""))
              || customRecorderStopEditor.text !== String(root.setting("recordingCustomStopCommand", ""))
            property var validation: Model.deviceBackendValidation("screen-recording", {
              recordingBackend: "custom",
              recordingProcessName: customRecorderProcessEditor.text,
              recordingCustomStartCommand: customRecorderStartEditor.text,
              recordingCustomStopCommand: customRecorderStopEditor.text
            })
            Text { Layout.fillWidth: true; text: "Recorder process name"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
            TextField {
              id: customRecorderProcessEditor
              Layout.fillWidth: true
              placeholderText: "Process command substring"
              text: String(root.setting("recordingProcessName", ""))
              maximumLength: 256
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: if (parent.validation.valid) root.persistSettings({recordingProcessName: text, recordingCustomStartCommand: customRecorderStartEditor.text, recordingCustomStopCommand: customRecorderStopEditor.text})
            }
            Text { Layout.fillWidth: true; text: "Start command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
            TextField {
              id: customRecorderStartEditor
              Layout.fillWidth: true
              placeholderText: "Start command"
              text: String(root.setting("recordingCustomStartCommand", ""))
              maximumLength: 4096
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: if (parent.validation.valid) root.persistSettings({recordingProcessName: customRecorderProcessEditor.text, recordingCustomStartCommand: text, recordingCustomStopCommand: customRecorderStopEditor.text})
            }
            Text { Layout.fillWidth: true; text: "Stop command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
            TextField {
              id: customRecorderStopEditor
              Layout.fillWidth: true
              placeholderText: "Stop command"
              text: String(root.setting("recordingCustomStopCommand", ""))
              maximumLength: 4096
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: if (parent.validation.valid) root.persistSettings({recordingProcessName: customRecorderProcessEditor.text, recordingCustomStartCommand: customRecorderStartEditor.text, recordingCustomStopCommand: text})
            }
            Text {
              Layout.fillWidth: true
              text: !parent.validation.valid ? parent.validation.message : (parent.dirty ? "Unsaved changes" : "Saved")
              textFormat: Text.PlainText
              color: !parent.validation.valid ? Color.urgent : (parent.dirty ? Color.accent : Color.muted)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
            Button {
              text: "Save custom backend"
              enabled: parent.dirty && parent.validation.valid
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
            text: "Shared by microphone and audio output. Auto prefers pactl and falls back to wpctl. This changes mute control only; activity detection remains PipeWire-native."
            textFormat: Text.PlainText
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
            }
          }

          DeviceDiagnostics { controller: root; kind: root.editingKind }

          SettingsSurface {
            id: resetSurface
            Layout.fillWidth: true
            accent: root.activeThemeColor
            PanelSectionHeader { Layout.fillWidth: true; text: "Reset device appearance" }
            RowLayout {
              Layout.fillWidth: true
              Button {
                text: "Reset device appearance"
                tooltipText: "Restore the default label, icon, colors, idle visibility, idle opacity, and status-marker visibility"
                onClicked: {
                  confirmationState.clear()
                  root.resetItemSettings(root.editingKind)
                  iconEditor.text = root.iconFor(root.editingKind)
                  labelEditor.text = root.labelFor(root.editingKind)
                }
              }
              Button {
                visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind})
                text: confirmationState.pending === "backend" ? "Confirm shared backend reset" : (root.isAudioControl({kind: root.editingKind}) ? "Reset shared backend" : "Reset backend")
                tooltipText: root.isAudioControl({kind: root.editingKind}) ? "Affects microphone and audio output" : "Restore this device's default backend"
                onClicked: {
                  if (root.isAudioControl({kind: root.editingKind}) && !confirmationState.request("backend")) return
                  root.resetDeviceBackend(root.editingKind)
                  confirmationState.clear()
                }
              }
            }
            Button {
              text: confirmationState.pending === "all" ? "Confirm reset all" : "Reset all device settings"
              onClicked: {
                if (root.isAudioControl({kind: root.editingKind}) && !confirmationState.request("all")) return
                root.resetAllDeviceSettings(root.editingKind)
                iconEditor.text = root.iconFor(root.editingKind)
                labelEditor.text = root.labelFor(root.editingKind)
                confirmationState.clear()
              }
            }
          }
        }

        GridLayout {
          id: activityRows
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory
          Layout.fillWidth: true
          columns: root.popupGridColumns
          columnSpacing: root.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
          rowSpacing: root.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md

          Repeater {
            // Do not retain main-widget delegates behind a settings/editor page.
            // An empty model prevents both visual leakage and needless bindings.
            model: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory
              ? root.displayedActivityItems
              : []
            delegate: PrivacyActivityCard {
              required property var modelData
              required property int index
              Layout.columnSpan: root.popupGridColumns === 2 && index === root.displayedActivityItems.length - 1 && root.displayedActivityItems.length % 2 === 1 ? 2 : 1
              entry: modelData
              controller: root
            }
          }
        }

        ColumnLayout {
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory && Model.arraySetting(root.setting("hiddenApps", []), []).length > 0
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
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory && (Model.arraySetting(root.setting("hiddenDevices", []), []).length > 0 || Model.arraySetting(root.setting("notificationSuppressedDevices", []), []).length > 0)
          Layout.fillWidth: true
          spacing: Style.spacing.sm
          PanelSectionHeader { Layout.fillWidth: true; text: "Device policies" }
          Text { Layout.fillWidth: true; text: "Hidden: " + (Model.arraySetting(root.setting("hiddenDevices", []), []).join(", ") || "None"); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
          Text { Layout.fillWidth: true; text: "Alerts muted: " + (Model.arraySetting(root.setting("notificationSuppressedDevices", []), []).join(", ") || "None"); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
          RowLayout {
            Button { text: "Restore hidden"; onClicked: root.clearPolicy("hiddenDevices") }
            Button { text: "Restore alerts"; onClicked: root.clearPolicy("notificationSuppressedDevices") }
          }
        }

        Text {
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory
          Layout.fillWidth: true
          text: "Keyboard: ↑/↓ select · Enter open · H history · S settings · R refresh · Esc close"
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

  PrivacySettingsTransferController {
    id: settingsTransferController
    helper: root.settingsHelperPath()
    onSucceeded: function(mode, payload) { root.handleSettingsTransfer(mode, payload) }
    onFailed: function(_mode, detail) { settingsTransferResult.fail(detail) }
  }
  PrivacySettingsTransferResult { id: settingsTransferResult; controller: root }

  Component { id: generalSettingsPage; PrivacyGeneralSettings { controller: root } }
  Component { id: appearanceSettingsPage; PrivacyAppearanceSettings { controller: root } }
  Component { id: alertsSettingsPage; PrivacyAlertsSettings { controller: root } }
  Component { id: monitoringSettingsPage; PrivacyMonitoringSettings { controller: root } }
}
