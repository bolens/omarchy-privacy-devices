pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons
import "Model.js" as Model

ShellRoot {
  id: root
  property var policies: []

  QtObject {
    id: controllerMock
    property string popupDensity: "comfortable"
    property int popupGridColumns: 1
    property real popupItemScale: 1
    property real popupIdleOpacity: 0.72
    property real disabledOpacity: 1
    property bool showStatePills: true
    property bool showControls: true
    property string statePillStyle: "filled"
    property string selectedKind: ""
    property string editingKind: ""
    property double durationNow: 10000
    property color inactiveThemeColor: Color.muted
    property color activeThemeColor: Color.accent
    property color mutedThemeColor: Color.urgent
    property color unmutedThemeColor: Color.foreground
    function itemVisualState(entry) { return Model.privacyVisualState(entry) }
    function itemColor(_entry) { return Color.accent }
    function itemIdleOpacity(_kind) { return 0.45 }
    function itemSessionCount(_entry) { return 1 }
    function itemStateLabel(entry) { return Model.privacyStateLabel(entry) }
    function deviceLabel(value) { return value }
    function isAudioControl(_entry) { return false }
    function toggleEntry(_entry) {}
    function addPolicyValue(key, value) { root.policies = root.policies.concat([{key:key,value:value}]) }
  }

  PrivacyActivityCard {
    id: card
    width: 500
    controller: controllerMock
    entry: ({
      kind:"camera",label:"Camera",icon:"C",active:true,apps:["Browser"],
      sessions:[{device:"Integrated camera",startedAt:9000,confidence:"confirmed"}],
      controllable:true,controlEnabled:true,pending:false,dependenciesReady:true,
      health:{status:"healthy",summary:"All monitoring sources healthy"}
    })
  }

  Component.onCompleted: Qt.callLater(function() {
    if (!card.hasPolicyActions || !card.hideApplication() || !card.hideDevice() || !card.muteDeviceAlerts())
      throw new Error("available activity privacy policy actions were rejected")
    if (root.policies.length !== 3
        || root.policies[0].key !== "hiddenApps" || root.policies[0].value !== "Browser"
        || root.policies[1].key !== "hiddenDevices" || root.policies[1].value !== "Integrated camera"
        || root.policies[2].key !== "notificationSuppressedDevices" || root.policies[2].value !== "Integrated camera")
      throw new Error("activity privacy actions persisted the wrong policy target")
    card.entry = ({kind:"camera",label:"Camera",icon:"C",active:false,apps:[],sessions:[],controllable:true,controlEnabled:true,pending:false,dependenciesReady:true,health:{status:"healthy",summary:""}})
    if (card.hasPolicyActions || card.hideApplication() || card.hideDevice() || card.muteDeviceAlerts() || root.policies.length !== 3)
      throw new Error("unavailable privacy policy targets reused stale activity data")
    card.entry = ({kind:"camera",label:"Camera",icon:"C",active:true,apps:["Conference"],sessions:[{device:"",startedAt:9500,confidence:"confirmed"}],controllable:true,controlEnabled:true,pending:false,dependenciesReady:true,health:{status:"healthy",summary:""}})
    if (!card.hasPolicyActions || !card.hideApplication() || card.hideDevice() || card.muteDeviceAlerts()
        || root.policies.length !== 4 || root.policies[3].value !== "Conference")
      throw new Error("activity privacy actions did not react to changed policy targets")
    console.log("PRIVACY_QML_ACTIVITY_POLICY_ACTIONS_OK")
    Qt.quit()
  })
}
