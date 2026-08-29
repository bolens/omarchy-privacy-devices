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
  readonly property real configuredPanelWidth: popupBaseWidth
  readonly property real configuredPopupHeight: Style.space(Math.max(360, Math.min(900, Number(setting("popupMaxHeight", 620)) || 620)))
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
  property alias editingKind: navigationController.editingKind
  property alias showingGlobalSettings: navigationController.showingGlobalSettings
  property alias showingHistory: navigationController.showingHistory
  property string historyQuery: ""
  property string historyKindFilter: "all"
  property string historyConfidenceFilter: "all"
  property string historySortMode: "recent"
  property int historySummaryWindow: 24 * 60 * 60 * 1000
  readonly property bool settingsMutationPending: settingsController.mutationPending
  property alias globalSettingsPage: navigationController.globalSettingsPage
  property alias globalSettingsSection: navigationController.globalSettingsSection
  property alias pendingSettingsSection: navigationController.pendingSettingsSection
  property alias selectedKind: navigationController.selectedKind
  property var displayedActivityItems: []
  property var deferredActivityItems: null
  property alias handledSettingsRequestSerial: navigationController.handledSettingsRequestSerial
  property double durationNow: Date.now()
  readonly property string settingsTransferStatus: settingsController.transferResult.status
  readonly property bool settingsTransferRunning: settingsController.transferControl.running
  readonly property bool settingsUndoAvailable: settingsController.transferControl.undoAvailable
  readonly property string settingsMutationMessage: settingsController.mutationMessage
  readonly property bool settingsPageLoaded: globalSettingsPageLoader.item !== null
  readonly property var confirmationController: confirmationState
  readonly property var contentViewport: contentFlick
  readonly property var settingsPageItem: globalSettingsPageLoader.item
  readonly property var settingsMutationControl: settingsController.mutationControl
  readonly property var lockdownActionControl: activityHeader.lockdownActionControl
  readonly property var privacyPresetFeedbackSurface: activityView.presetFeedbackSurface
  readonly property string confirmationPending: confirmationState.pending
  readonly property var historySearchControl: historyView.searchControl
  readonly property var historyCountLabel: historyView.countLabel
  readonly property var historyDisabledSettingsControl: historyView.disabledSettingsControl
  readonly property var historyFilterControls: historyView.filterControls
  readonly property var deviceEditorIconControl: deviceView.iconEditorControl
  readonly property var deviceEditorLabelControl: deviceView.labelEditorControl
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
      settingsSection: view === "settings" ? globalSettingsSection : "",
      settingsScroll: view === "settings" ? navigationController.settingsScrollPosition : "",
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

  function showGlobalSettings(page, section) { navigationController.showSettings(page, section) }

  function scrollToSettingsSection() { navigationController.scrollToSettingsSection() }
  function applySettingsScroll(position) { return navigationController.applySettingsScroll(position) }

  function showActivity() { navigationController.showActivity() }

  function showHistory() { navigationController.showHistory() }

  function requestHistoryClear() {
    if (!confirmationState.request("history")) return
    if (privacyService) privacyService.clearHistory()
  }

  function handleSettingsRequest() { navigationController.handleRequest() }

  function closeCurrentLayer() { navigationController.closeCurrentLayer() }

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

  function moveActivitySelection(delta) { navigationController.moveActivitySelection(delta) }

  function activateActivitySelection() { navigationController.activateActivitySelection() }

  function moveDeviceEditor(delta) { navigationController.moveDeviceEditor(delta) }

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

  function item(kind) { return presentationController.item(kind) }
  function barItem(kind) { return presentationController.barItem(kind) }
  function themeColor(role, activeFallback) { return presentationController.themeColor(role, activeFallback) }
  function deviceDiagnostic(kind) { return presentationController.deviceDiagnostic(kind) }
  function isAudioControl(entry) { return presentationController.isAudioControl(entry) }
  function isPreventativeControl(entry) { return presentationController.isPreventativeControl(entry) }
  function itemVisualState(entry) { return presentationController.itemVisualState(entry) }
  function itemStateLabel(entry) { return presentationController.itemStateLabel(entry) }
  function itemStatusMarkerVisible(kind) { return presentationController.itemStatusMarkerVisible(kind) }
  function itemStateMarker(entry) { return presentationController.itemStateMarker(entry) }
  function itemSessionCount(entry) { return presentationController.itemSessionCount(entry) }
  function barItemText(entry) { return presentationController.barItemText(entry) }
  function itemColor(entry) { return presentationController.itemColor(entry) }

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

  function persistIcon(kind, value) { deviceSettingsController.persistIcon(kind, value) }
  function labelFor(kind) { return deviceSettingsController.labelFor(kind) }
  function persistLabel(kind, value) { deviceSettingsController.persistLabel(kind, value) }
  function persistItemColor(kind, state, role) { deviceSettingsController.persistItemColor(kind, state, role) }
  function persistItemStatusMarker(kind, mode) { deviceSettingsController.persistItemStatusMarker(kind, mode) }
  function itemColorRole(kind, state, fallback) { return deviceSettingsController.itemColorRole(kind, state, fallback) }
  function itemColorOverrideRole(kind, state) { return deviceSettingsController.itemColorOverrideRole(kind, state) }
  function itemOverrideMode(group, kind) { return deviceSettingsController.itemOverrideMode(group, kind) }
  function moveItem(kind, delta) { deviceSettingsController.moveItem(kind, delta) }
  function canMoveItem(kind, delta) { return deviceSettingsController.canMoveItem(kind, delta) }
  function itemShowsWhenIdle(kind) { return deviceSettingsController.itemShowsWhenIdle(kind) }
  function persistItemIdleVisibility(kind, mode) { deviceSettingsController.persistItemIdleVisibility(kind, mode) }
  function itemIdleOpacity(kind) { return deviceSettingsController.itemIdleOpacity(kind) }
  function persistItemIdleOpacity(kind, percent) { deviceSettingsController.persistItemIdleOpacity(kind, percent) }
  function itemResetValues(kind) { return deviceSettingsController.itemResetValues(kind) }
  function resetItemSettings(kind) { deviceSettingsController.resetItemSettings(kind) }
  function deviceBackendDefaults(kind) { return deviceSettingsController.deviceBackendDefaults(kind) }
  function resetDeviceBackend(kind) { deviceSettingsController.resetDeviceBackend(kind) }
  function resetAllDeviceSettings(kind) { deviceSettingsController.resetAllDeviceSettings(kind) }

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

  function enabled(kind) { return presentationController.enabled(kind) }
  function orderedKinds() { return presentationController.orderedKinds() }
  function activeItems() { return presentationController.activeItems() }
  function iconFor(kind) { return presentationController.iconFor(kind) }
  function defaultIcon(kind) { return presentationController.defaultIcon(kind) }
  function deviceAppearanceCustomized(kind) { return presentationController.deviceAppearanceCustomized(kind) }
  function sharedText(value) { return presentationController.sharedText(value) }
  function barText() { return presentationController.barText() }
  function tooltip() { return presentationController.tooltip() }
  function itemTooltip(entry) { return presentationController.itemTooltip(entry) }

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
  onPrivacyServiceChanged: Qt.callLater(function() {
    if (!root) return
    root.syncService()
    root.publishCaptureBarPresentation()
  })
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
  onGlobalSettingsSectionChanged: Qt.callLater(publishCaptureBarPresentation)
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
  PrivacyPopupNavigationController { id: navigationController; host: root }
  PrivacySettingsController { id: settingsController; host: root }
  PrivacyDeviceSettingsController { id: deviceSettingsController; host: root }
  PrivacyPresentationController { id: presentationController; host: root }

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
    contentHeight: fittedContentHeight(root.configuredPopupHeight, root.configuredPopupHeight)

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

      Item {
        id: popupLayout
        anchors.fill: parent
        implicitHeight: root.configuredPopupHeight

        ColumnLayout {
          id: popupHeaderChrome
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: Style.spacing.md

        PrivacyActivityHeader {
          id: activityHeader
          visible: root.editingKind === "" && !root.showingGlobalSettings && !root.showingHistory
          controller: root
          Layout.fillWidth: true
        }

        PrivacySettingsNavigation {
          visible: root.showingGlobalSettings
          controller: root
          Layout.fillWidth: true
        }

        PanelSeparator {
          visible: root.showingGlobalSettings
          Layout.fillWidth: true
          foreground: root.bar ? root.bar.foreground : Color.popups.text
        }
        }

        Item {
        id: contentViewportFrame
        implicitHeight: 0
        anchors.top: popupHeaderChrome.bottom
        anchors.bottom: popupFooterChrome.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Style.spacing.md
        anchors.bottomMargin: Style.spacing.md

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

        }

        PrivacyDeviceView {
          id: deviceView
          controller: root
        }

        }
      }
      }

        ColumnLayout {
          id: popupFooterChrome
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: Style.spacing.md

        PanelSeparator {
          visible: root.showingGlobalSettings
          Layout.fillWidth: true
          foreground: root.bar ? root.bar.foreground : Color.popups.text
        }

        Button {
          visible: root.showingGlobalSettings
          Layout.alignment: Qt.AlignRight
          iconText: "󰑐"
          tooltipText: "Reset all global settings"
          horizontalPadding: Style.spacing.controlGap
          bordered: true
          background: Util.alpha(root.activeThemeColor, 0.06)
          enabled: !root.settingsTransferRunning
          onClicked: root.requestGlobalSettingsReset()
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

  Component { id: generalSettingsPage; PrivacyGeneralSettings { controller: root } }
  Component { id: appearanceSettingsPage; PrivacyAppearanceSettings { controller: root } }
  Component { id: alertsSettingsPage; PrivacyAlertsSettings { controller: root } }
  Component { id: monitoringSettingsPage; PrivacyMonitoringSettings { controller: root } }
}
