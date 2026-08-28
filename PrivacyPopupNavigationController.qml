import QtQuick
import "Model.js" as Model

Item {
  id: controller
  required property var host

  property string editingKind: ""
  property bool showingGlobalSettings: false
  property bool showingHistory: false
  property string globalSettingsPage: "general"
  property string pendingSettingsSection: ""
  property string selectedKind: ""
  property int handledSettingsRequestSerial: 0

  function showSettings(page, section) {
    host.confirmationController.clear()
    var target = Model.settingsDeepLink(page, section)
    editingKind = ""
    showingHistory = false
    showingGlobalSettings = true
    globalSettingsPage = target.page
    pendingSettingsSection = target.section
    host.contentViewport.contentY = 0
    Qt.callLater(controller.scrollToSettingsSection)
  }

  function scrollToSettingsSection() {
    var page = host.settingsPageItem
    if (!pendingSettingsSection || !page || !page.sectionItems) return
    var target = page.sectionItems[pendingSettingsSection]
    if (!target) { pendingSettingsSection = ""; return }
    var position = target.mapToItem(host.contentViewport.contentItem, 0, 0)
    host.contentViewport.contentY = Model.settingsScrollPosition(position.y, host.contentViewport.contentHeight, host.contentViewport.height)
    pendingSettingsSection = ""
  }

  function showActivity() {
    host.confirmationController.clear()
    editingKind = ""
    showingGlobalSettings = false
    showingHistory = false
    host.contentViewport.contentY = 0
  }

  function showHistory() {
    host.confirmationController.clear()
    editingKind = ""
    showingGlobalSettings = false
    showingHistory = true
    host.contentViewport.contentY = 0
    if (host.privacyService) host.privacyService.loadHistory()
  }

  function handleRequest() {
    var service = host.privacyService
    if (!host.opened || !service || service.settingsRequestSerial <= handledSettingsRequestSerial) return
    handledSettingsRequestSerial = service.settingsRequestSerial
    if (service.requestedView === "history") {
      host.historyQuery = service.requestedViewArgument ? Model.label(service.requestedViewArgument) : ""
      showHistory()
    } else if (service.requestedView === "activity") {
      showActivity()
      editingKind = Model.KINDS.indexOf(service.requestedViewArgument) >= 0 ? service.requestedViewArgument : ""
    } else if (service.requestedView === "lockdown") {
      showActivity()
      host.confirmationController.request("lockdown")
    } else if (service.requestedView === "diagnostics") showSettings("monitoring", "observer-health")
    else showSettings(service.requestedSettingsPage, service.requestedSettingsSection)
  }

  function closeCurrentLayer() {
    var action = Model.popupDismissalAction(editingKind, showingGlobalSettings, showingHistory)
    if (action === "device") { editingKind = ""; return }
    if (action === "settings" || action === "history") { showActivity(); return }
    host.close()
  }

  function moveActivitySelection(delta) {
    var kinds = host.displayedActivityItems.map(function(entry) { return entry.kind })
    selectedKind = Model.nextNavigationKind(kinds, selectedKind, delta)
  }

  function activateActivitySelection() {
    var kinds = host.displayedActivityItems.map(function(entry) { return entry.kind })
    var target = Model.activationKind(kinds, selectedKind)
    selectedKind = target
    if (target) {
      showingGlobalSettings = false
      showingHistory = false
      editingKind = target
      host.contentViewport.contentY = 0
    }
  }

  function moveDeviceEditor(delta) {
    var order = host.orderedKinds()
    var target = Model.nextNavigationKind(order, editingKind, delta)
    if (!target || target === editingKind) return
    editingKind = target
    selectedKind = editingKind
    host.contentViewport.contentY = 0
  }
}
