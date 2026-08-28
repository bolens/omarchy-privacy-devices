import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var patches: []
  property int testNotifications: 0

  QtObject { id: serviceMock; function sendTestNotification() { root.testNotifications++ } }
  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property string popupWidth: "standard"
    property var privacyService: serviceMock
    property var kindOptions: [{label:"Microphone",value:"microphone"},{label:"Camera",value:"camera"}]
    property var values: ({notificationKinds:["camera"],notifyOnActivity:true,notifyOnStop:false,notifyOnControlChanges:false,notifyOnObserverHealth:true,notificationSuppressedApps:["Firefox"]})
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
    function commaList(value) {
      var seen = {}
      return String(value || "").split(",").map(function(entry) { return entry.trim() }).filter(function(entry) {
        if (!entry || seen[entry]) return false
        seen[entry] = true
        return true
      })
    }
  }

  PrivacyAlertsSettings { id: page; width: 500; controller: controllerMock }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) {
      var found = descendant(children[index], name)
      if (found) return found
    }
    return null
  }

  Component.onCompleted: Qt.callLater(function() {
    var kinds = descendant(page, "alertsNotificationKindsSetting")
    var activity = descendant(page, "alertsNotifyOnActivityToggle")
    var stop = descendant(page, "alertsNotifyOnStopToggle")
    var controls = descendant(page, "alertsNotifyOnControlChangesToggle")
    var health = descendant(page, "alertsNotifyOnObserverHealthToggle")
    var editor = descendant(page, "alertsSuppressedAppsEditor")
    var save = descendant(page, "alertsSaveSuppressedAppsButton")
    var send = descendant(page, "alertsSendTestButton")
    if (!kinds || !activity || !stop || !controls || !health || !editor || !save || !send)
      throw new Error("alert settings controls are not addressable")
    if (save.text !== "" || save.iconText !== "󰆓" || save.tooltipText !== "Save muted applications"
        || send.text !== "" || send.iconText !== "󰂚" || send.tooltipText !== "Send test notification")
      throw new Error("alert actions are not descriptive icon controls")
    if (kinds.values[0] !== "camera" || !activity.checked || stop.checked || controls.checked || !health.checked
        || editor.text !== "Firefox" || !send.enabled)
      throw new Error("alert settings controls did not reflect configured values")
    kinds.changed(["microphone"])
    stop.clicked()
    editor.text = "Firefox, OBS, Firefox"
    save.clicked()
    send.clicked()
    if (root.patches.length !== 3 || root.patches[0].notificationKinds[0] !== "microphone"
        || root.patches[1].notifyOnStop !== true || root.patches[2].notificationSuppressedApps.join("|") !== "Firefox|OBS"
        || root.testNotifications !== 1)
      throw new Error("alert settings actions dispatched incorrect values")
    console.log("PRIVACY_QML_ALERTS_SETTINGS_OK")
    Qt.quit()
  })
}
