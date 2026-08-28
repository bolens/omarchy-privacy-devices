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
  readonly property bool showIdle: setting("showIdle", false) === true
  readonly property string displayMode: String(setting("displayMode", "icons"))
  readonly property bool showControls: setting("showControls", true) === true
  readonly property real idleOpacity: Math.max(0.1, Math.min(1, Number(setting("idleOpacity", 0.45))))
  readonly property real activeOpacity: Math.max(0.1, Math.min(1, Number(setting("activeOpacity", 1))))
  readonly property real disabledOpacity: Math.max(0.25, Math.min(1, Number(setting("disabledOpacity", 1))))
  readonly property real blockedActiveOpacity: Math.max(0.1, Math.min(1, Number(setting("blockedActiveOpacity", 1))))
  readonly property string statusMarkerMode: String(setting("statusMarkerMode", "off"))
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
  readonly property color activeThemeColor: themeColor(String(setting("activeColorRole", "accent")), true)
  readonly property color inactiveThemeColor: themeColor(String(setting("inactiveColorRole", "foreground")), false)
  readonly property color disabledThemeColor: themeColor(String(setting("disabledColorRole", "muted")), false)
  readonly property color blockedActiveThemeColor: themeColor(String(setting("blockedActiveColorRole", "urgent")), true)
  readonly property color mutedThemeColor: themeColor(String(setting("mutedColorRole", "urgent")), true)
  readonly property color unmutedThemeColor: themeColor(String(setting("unmutedColorRole", "foreground")), false)
  readonly property var activitySourceItems: orderedKinds().map(function(kind) { return item(kind) })
  readonly property var barSourceItems: orderedKinds().map(function(kind) { return barItem(kind) })
  readonly property var visibleItems: barSourceItems.filter(function(entry) { return entry.active || itemShowsWhenIdle(entry.kind) })
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
    ? [{kind: "summary", label: "Privacy", icon: activeCount > 0 ? "󰒃 " + activeCount : "󰒃", active: activeCount > 0, apps: [], controllable: false, controlEnabled: false, pending: false, dependenciesReady: true, health: {status: "healthy"}, sessions: []}]
    : (displayMode === "active-only" ? activeItems() : visibleItems)
  readonly property var liveBarItems: monitoringDegraded && normalBarItems.length === 0
    ? [{kind: "summary", label: "Privacy", icon: "󰀦", active: false, apps: [], controllable: false, controlEnabled: false, health: {status: "degraded"}, sessions: []}]
    : normalBarItems
  property var captureFrozenBarItems: []
  readonly property var barItems: privacyService && privacyService.capturePreviewActive && captureFrozenBarItems.length > 0
    ? captureFrozenBarItems : liveBarItems
  readonly property bool verticalBar: bar && bar.vertical === true
  readonly property int barFlowColumns: iconGrid.columns
  property string editingKind: ""
  property bool showingGlobalSettings: false
  property bool showingHistory: false
  property string historyQuery: ""
  property string historyKindFilter: "all"
  property string historyConfidenceFilter: "all"
  property string historySortMode: "recent"
  property int historySummaryWindow: 24 * 60 * 60 * 1000
  readonly property bool settingsMutationPending: settingsController.mutationPending
  property string globalSettingsPage: "general"
  property string pendingSettingsSection: ""
  property string selectedKind: ""
  property var displayedActivityItems: []
  property var deferredActivityItems: null
  property int handledSettingsRequestSerial: 0
  property double durationNow: Date.now()
  readonly property string settingsTransferStatus: settingsController.transferResult.status
  readonly property bool settingsTransferRunning: settingsController.transferControl.running
  readonly property bool settingsUndoAvailable: settingsController.transferControl.undoAvailable
  readonly property string settingsMutationMessage: settingsController.mutationMessage
  readonly property bool settingsPageLoaded: globalSettingsPageLoader.item !== null
  readonly property var confirmationController: confirmationState
  readonly property var settingsMutationControl: settingsController.mutationControl
  readonly property var lockdownActionControl: activityView.lockdownActionControl
  readonly property var privacyPresetFeedbackSurface: activityView.presetFeedbackSurface
  readonly property string confirmationPending: confirmationState.pending
  readonly property var historySearchControl: historyView.searchControl
  readonly property var historyCountLabel: historyView.countLabel
  readonly property var historyDisabledSettingsControl: historyView.disabledSettingsControl
  readonly property var historyFilterControls: historyView.filterControls
  readonly property var filteredHistory: Model.filterAndSortHistory(privacyService ? privacyService.displayHistory : [], {
    query: historyQuery, kind: historyKindFilter, confidence: historyConfidenceFilter, sort: historySortMode
  })
  readonly property var historySummaryRows: Model.historySummary(privacyService ? privacyService.displayHistory : [], durationNow, historySummaryWindow)
  readonly property var historyTrend: Model.historyTrend(privacyService ? privacyService.displayHistory : [], durationNow, historySummaryWindow, 12)
  readonly property bool historyPresentationEnabled: privacyService && privacyService.capturePreviewActive && privacyService.requestedView === "history"
    ? privacyService.captureHistoryPresentationEnabled !== false : setting("historyEnabled", false) === true
  readonly property var editingSessions: editingKind && privacyService ? privacyService.attributedSessionsFor(editingKind) : []
  readonly property var editingDevices: Model.unique(editingSessions.map(function(session) { return String(session.device || "") }).filter(Boolean))
  readonly property var editingApplications: Model.unique(editingSessions.map(function(session) { return String(session.application || "") }).filter(Boolean))
  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property var presentationScreen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property string presentationScreenName: presentationScreen ? presentationScreen.name : "unknown"
  property string registeredPresentationScreen: ""

  function setting(key, fallback) {
    return effectiveSettings && effectiveSettings[key] !== undefined ? effectiveSettings[key] : fallback
  }

  function mutationSetting(key, fallback) {
    var candidate = settingsController.mutationControl.pending || effectiveSettings
    return candidate && candidate[key] !== undefined ? candidate[key] : fallback
  }

  function publishCaptureBarPresentation() {
    if (!privacyService) return
    if (registeredPresentationScreen !== presentationScreenName) {
      if (registeredPresentationScreen) privacyService.unregisterBarInstance(registeredPresentationScreen, root)
      registeredPresentationScreen = presentationScreenName
    }
    privacyService.registerBarInstance(presentationScreenName, root)
    var view = showingGlobalSettings ? "settings" : (showingHistory ? "history" : (editingKind ? "device" : "activity"))
    privacyService.updateBarPresentation(presentationScreenName, {
      opened: opened,
      view: view,
      argument: view === "device" ? editingKind : "",
      settingsPage: globalSettingsPage,
      settingsSection: view === "settings" ? privacyService.requestedSettingsSection : "",
      ready: opened && !contentFlick.moving && (view !== "settings" || (settingsPageLoaded && pendingSettingsSection === "")),
      requestSerial: handledSettingsRequestSerial
    })
  }

  function syncService() {
    if (privacyService && typeof privacyService.configure === "function") privacyService.configure(Model.sanitizeSettings(settings))
  }

  function syncDeviceEditors() {
    deviceView.syncEditors()
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

  function activateLockdownAction() {
    if (!privacyService || privacyService.privacyPresetState === "applying" || privacyService.privacyPresetState === "restoring") return false
    var presentation = Model.lockdownActionPresentation(privacyService.privacyPresetUndoAvailable, confirmationState.pending === "lockdown")
    if (presentation.action === "restore") {
      var restored = privacyService.restorePrivacyLockdown()
      confirmationState.clear()
      return restored
    }
    if (!confirmationState.request("lockdown")) return false
    var requested = privacyService.requestPrivacyLockdown()
    confirmationState.clear()
    return requested
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
    var labels = Object.assign({}, mutationSetting("deviceLabels", {}) || {})
    var key = String(device || "")
    var text = String(value || "").trim()
    if (!key) return
    if (text && text !== key) labels[key] = text
    else delete labels[key]
    persistSettings({deviceLabels: labels})
  }

  function currentPrivacyMode(name) {
    var controls = {}
    if (privacyService) ["microphone", "audio-output", "camera", "screen-share", "location"].forEach(function(kind) {
      if (privacyService.serviceControllable(kind)) controls[kind] = privacyService.controlEnabled(kind) === true
    })
    return {name: String(name || ""), controls: controls}
  }

  function savePrivacyMode(name) {
    var saved = setting("privacyModes", [])
    var modes = Model.sanitizePrivacyModes((Array.isArray(saved) ? saved : []).concat([currentPrivacyMode(name)]))
    persistSettings({privacyModes: modes})
  }

  function removePrivacyMode(index) {
    var modes = Model.sanitizePrivacyModes(setting("privacyModes", []))
    if (index < 0 || index >= modes.length) return
    modes.splice(index, 1)
    persistSettings({privacyModes: modes})
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

  function barItem(kind) {
    var entry = item(kind)
    if (!privacyService || typeof privacyService.barActive !== "function") return entry
    entry.active = privacyService.barActive(kind)
    entry.apps = privacyService.barAppsFor(kind)
    entry.sessions = privacyService.barAttributedSessionsFor(kind)
    return entry
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
      : (state === "disabled" || state === "blocked-active" ? showBarDisabledMarker
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
    if (state === "blocked-active") return themeColor(String(override.blocked || setting("blockedActiveColorRole", "urgent")), true)
    if (state === "disabled") return themeColor(String(override.disabled || setting("disabledColorRole", "muted")), false)
    return state === "active"
      ? themeColor(String(override.active || setting("activeColorRole", "accent")), true)
      : themeColor(String(override.inactive || setting("inactiveColorRole", "foreground")), false)
  }

  function persistSettings(values) {
    settingsController.persist(values)
  }

  function commitSettings(candidate) {
    settingsController.commit(candidate)
  }

  function settingsHelperPath() {
    return String(Qt.resolvedUrl("privacy-settings")).replace(/^file:\/\//, "")
  }

  function exportSettings() {
    settingsController.exportSettings()
  }

  function importSettings() {
    settingsController.importSettings()
  }

  function undoSettingsChange() {
    settingsController.undoSettingsChange()
  }

  function requestGlobalSettingsReset() {
    settingsController.requestGlobalSettingsReset()
  }

  function handleSettingsTransfer(mode, payload) {
    settingsController.handleTransfer(mode, payload)
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
      showIdle: false,
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
      activeOpacity: 1,
      disabledOpacity: 1,
      blockedActiveOpacity: 1,
      activeColorRole: "accent",
      inactiveColorRole: "foreground",
      disabledColorRole: "muted",
      blockedActiveColorRole: "urgent",
      statusMarkerMode: "off",
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
    var icons = JSON.parse(JSON.stringify(mutationSetting("icons", {}) || {}))
    icons[kind] = String(value || "")
    persistSettings({icons: icons})
    Qt.callLater(function() { if (root.editingKind === kind) deviceView.iconEditorControl.text = root.iconFor(kind) })
  }

  function labelFor(kind) {
    var labels = setting("itemLabels", {}) || {}
    return labels[kind] !== undefined && String(labels[kind]) !== "" ? String(labels[kind]) : Model.label(kind)
  }

  function persistLabel(kind, value) {
    var labels = JSON.parse(JSON.stringify(mutationSetting("itemLabels", {}) || {}))
    var text = String(value || "").trim()
    if (text) labels[kind] = text
    else delete labels[kind]
    persistSettings({itemLabels: labels})
    Qt.callLater(function() { if (root.editingKind === kind) deviceView.labelEditorControl.text = root.labelFor(kind) })
  }

  function persistItemColor(kind, state, role) {
    var roles = JSON.parse(JSON.stringify(mutationSetting("itemColorRoles", {}) || {}))
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
    var visibility = JSON.parse(JSON.stringify(mutationSetting("itemStatusMarkerVisibility", {}) || {}))
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
    var overrides = JSON.parse(JSON.stringify(mutationSetting("itemIdleVisibility", {}) || {}))
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
    var overrides = JSON.parse(JSON.stringify(mutationSetting("itemIdleOpacity", {}) || {}))
    if (percent === null || percent === undefined) delete overrides[kind]
    else overrides[kind] = Math.max(10, Math.min(100, Number(percent))) / 100
    persistSettings({itemIdleOpacity: overrides})
  }

  function itemResetValues(kind) {
    var icons = JSON.parse(JSON.stringify(mutationSetting("icons", {}) || {}))
    var roles = JSON.parse(JSON.stringify(mutationSetting("itemColorRoles", {}) || {}))
    var visibility = JSON.parse(JSON.stringify(mutationSetting("itemIdleVisibility", {}) || {}))
    var opacity = JSON.parse(JSON.stringify(mutationSetting("itemIdleOpacity", {}) || {}))
    var markerVisibility = JSON.parse(JSON.stringify(mutationSetting("itemStatusMarkerVisibility", {}) || {}))
    var labels = JSON.parse(JSON.stringify(mutationSetting("itemLabels", {}) || {}))
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
    Qt.callLater(publishCaptureBarPresentation)
    if (privacyService && isAudioControl({kind: editingKind})) privacyService.refreshAudioEndpoints(editingKind)
  }
  onPrivacyServiceChanged: Qt.callLater(function() { syncService(); publishCaptureBarPresentation() })
  onActivitySourceItemsChanged: syncDisplayedItems()
  onOpenedChanged: {
    publishCaptureBarPresentation()
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
  onShowingGlobalSettingsChanged: Qt.callLater(publishCaptureBarPresentation)
  onShowingHistoryChanged: Qt.callLater(publishCaptureBarPresentation)
  onGlobalSettingsPageChanged: Qt.callLater(publishCaptureBarPresentation)
  onPendingSettingsSectionChanged: Qt.callLater(publishCaptureBarPresentation)
  onSettingsPageLoadedChanged: Qt.callLater(publishCaptureBarPresentation)
  onHandledSettingsRequestSerialChanged: Qt.callLater(publishCaptureBarPresentation)
  onPresentationScreenNameChanged: Qt.callLater(publishCaptureBarPresentation)
  Connections {
    target: root.privacyService
    function onCapturePreviewActiveChanged() {
      root.captureFrozenBarItems = root.privacyService && root.privacyService.capturePreviewActive
        ? root.liveBarItems.map(function(entry) { return Object.assign({}, entry) }) : []
    }
  }
  Connections {
    target: root.privacyService
    function onSettingsRequestSerialChanged() { root.handleSettingsRequest() }
  }
  Component.onCompleted: { syncDisplayedItems(); Qt.callLater(syncService) }
  Component.onDestruction: if (privacyService) privacyService.unregisterBarInstance(registeredPresentationScreen, root)

  PrivacyConfirmationController { id: confirmationState }
  PrivacySettingsController { id: settingsController; host: root }

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
            : (root.itemVisualState(modelData) === "disabled" ? root.disabledOpacity
            : (root.itemVisualState(modelData) === "blocked-active" ? root.blockedActiveOpacity : root.activeOpacity))
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

        PrivacyActivityView {
          id: activityView
          controller: root
        }

        PrivacyHistoryView {
          id: historyView
          controller: root
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
            kind: settingsMutationControl.status === "failed" ? "error" : (settingsMutationControl.status === "saved" ? "success" : "info")
          }

          Loader {
            id: globalSettingsPageLoader
            Layout.fillWidth: true
            sourceComponent: root.globalSettingsPage === "general" ? generalSettingsPage
              : (root.globalSettingsPage === "appearance" ? appearanceSettingsPage
              : (root.globalSettingsPage === "alerts" ? alertsSettingsPage : monitoringSettingsPage))
            onLoaded: Qt.callLater(root.scrollToSettingsSection)
          }

          Button { Layout.alignment: Qt.AlignRight; iconText: "󰑐"; text: "Reset global settings"; bordered: true; background: Util.alpha(root.activeThemeColor, 0.06); enabled: !root.settingsTransferRunning; onClicked: root.requestGlobalSettingsReset() }
        }

        PrivacyDeviceView {
          id: deviceView
          controller: root
        }

        }
      }
    }
  }

  Component { id: generalSettingsPage; PrivacyGeneralSettings { controller: root } }
  Component { id: appearanceSettingsPage; PrivacyAppearanceSettings { controller: root } }
  Component { id: alertsSettingsPage; PrivacyAlertsSettings { controller: root } }
  Component { id: monitoringSettingsPage; PrivacyMonitoringSettings { controller: root } }
}
