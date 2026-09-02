pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons
import "Model.js" as Model
// Imported JavaScript namespaces are valid here but Qt treats nested test objects as unqualified.
// qmllint disable unqualified

ShellRoot {
  id: root

  QtObject {
    id: controllerMock
    property string popupDensity: "comfortable"
    property int popupGridColumns: 1
    property real popupItemScale: 1
    property real popupIdleOpacity: 0.72
    property real disabledOpacity: 1
    property bool showStatePills: true
    property bool showControls: false
    property string statePillStyle: "filled"
    property string selectedKind: ""
    property string editingKind: ""
    property double durationNow: 70000
    property color inactiveThemeColor: Color.muted
    property color activeThemeColor: Color.accent
    property color mutedThemeColor: Color.urgent
    property color unmutedThemeColor: Color.foreground
    function itemVisualState(entry) { return Model.privacyVisualState(entry) }
    function itemColor(_entry) { return Color.accent }
    function itemIdleOpacity(_kind) { return 0.45 }
    function itemSessionCount(entry) { return entry.sessions.length }
    function itemStateLabel(entry) { return Model.privacyStateLabel(entry) }
    function deviceLabel(value) { return value === "alsa_input.raw" ? "Desk microphone" : value }
    function isAudioControl(_entry) { return false }
    function toggleEntry(_entry) {}
    function addPolicyValue(_key, _value) {}
  }

  PrivacyActivityCard {
    id: card
    width: 500
    controller: controllerMock
    entry: ({
      kind:"microphone",label:"Microphone",icon:"M",active:true,apps:["Recorder"],
      sessions:[
        {device:"alsa_input.raw",startedAt:10000,confidence:"inferred"},
        {device:"alsa_input.backup",startedAt:40000,confidence:"confirmed"}
      ],
      controllable:true,controlEnabled:true,pending:false,dependenciesReady:true,
      health:{status:"healthy",summary:""}
    })
  }

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
    var summary = descendant(card, "activitySessionSummary")
    var count = descendant(card, "activitySessionCount")
    var countBadge = descendant(card, "activitySessionCountBadge")
    if (!summary || !count || !countBadge) throw new Error("activity session presentation is not addressable")
    if (summary.text !== "Desk microphone · 1m 0s · Inferred · +1 more" || count.text !== "2")
      throw new Error("activity session summary omitted attribution metadata")
    controllerMock.durationNow = 75000
    card.entry = Object.assign({}, card.entry, {sessions:[{device:"alsa_input.raw",startedAt:10000,confidence:"confirmed"}]})
    Qt.callLater(function() {
      if (summary.text !== "Desk microphone · 1m 5s" || countBadge.visible)
        throw new Error("activity session summary did not react to elapsed time and session removal")
      console.log("PRIVACY_QML_ACTIVITY_SESSION_SUMMARY_OK")
      Qt.quit()
    })
  })
}
