import QtQuick
import "Model.js" as Model

Item {
  id: controller

  required property var host
  property bool active: false
  property var history: []
  property var sessions: []
  property var barSessions: []
  property var previewSettings: ({})
  property var presentations: ({})
  property var instances: ({})
  property bool historyPresentationEnabled: true
  property string owner: ""
  property double expiresAt: 0

  function updatePresentation(screenName, presentation) {
    var next = Object.assign({}, presentations)
    next[String(screenName || "unknown")] = presentation || ({})
    presentations = next
  }

  function anyBarOpen() {
    var names = Object.keys(presentations)
    for (var index = 0; index < names.length; index++) if (presentations[names[index]].opened === true) return true
    return false
  }

  function presentation(screenName) {
    return presentations[String(screenName || "unknown")] || ({})
  }

  function register(screenName, instance) {
    var key = String(screenName || "")
    if (!key || key === "unknown" || !instance) return false
    var next = Object.assign({}, instances)
    next[key] = instance
    instances = next
    return true
  }

  function unregister(screenName, instance) {
    var key = String(screenName || "")
    if (!key || instances[key] !== instance) return false
    var next = Object.assign({}, instances)
    delete next[key]
    instances = next
    return true
  }

  function closePanel(requestOwner, screenName) {
    if (!active || owner !== requestOwner) return "denied"
    var target = instances[String(screenName || "")]
    if (!target || typeof target.close !== "function") return "unavailable"
    target.close()
    return "ok"
  }

  function openPanel(requestOwner, screenName, mode, page, section) {
    if (!active || owner !== requestOwner) return "denied"
    var target = instances[String(screenName || "")]
    if (!target || typeof target.open !== "function") return "unavailable"
    var selected = String(mode || "")
    if (["settings", "settings-section", "device", "activity", "history", "history-disabled"].indexOf(selected) < 0) return "invalid"
    target.open()
    if (selected === "settings" || selected === "settings-section") target.showGlobalSettings(page, selected === "settings-section" ? section : "")
    else if (selected === "device") { target.showActivity(); target.editingKind = Model.deviceDeepLink(page) }
    else if (selected === "activity") target.showActivity()
    else {
      historyPresentationEnabled = selected !== "history-disabled"
      target.showHistory()
    }
    return selected === "settings" ? String(page || "general")
      : (selected === "settings-section" ? String(page || "general") + "#" + String(section || "")
      : (selected === "history-disabled" ? "history-disabled" : (selected === "device" ? "activity" : selected)))
  }

  function clear() {
    history = []
    sessions = []
    barSessions = []
    previewSettings = ({})
    historyPresentationEnabled = true
    owner = ""
    expiresAt = 0
    active = false
  }

  Timer {
    interval: 1000
    repeat: true
    running: controller.active
    onTriggered: if (Date.now() >= controller.expiresAt) controller.clear()
  }
}
