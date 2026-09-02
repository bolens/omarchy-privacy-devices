pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons
import "Model.js" as Model

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
    function itemColor(entry) { return itemVisualState(entry) === "blocked-active" ? Color.urgent : Color.accent }
    function itemIdleOpacity(_kind) { return 0.45 }
    function itemSessionCount(_entry) { return 0 }
    function itemStateLabel(entry) { return Model.privacyStateLabel(entry) }
    function deviceLabel(value) { return value }
    function isAudioControl(_entry) { return false }
    function toggleEntry(_entry) {}
    function addPolicyValue(_key, _value) {}
  }

  PrivacyActivityCard {
    id: card
    width: 500
    controller: controllerMock
    entry: ({
      kind:"camera",label:"Camera",icon:"C",active:true,apps:["Browser"],sessions:[],
      controllable:true,controlEnabled:false,pending:false,dependenciesReady:true,
      health:{status:"healthy",summary:"All monitoring sources healthy"}
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
    var description = descendant(card, "activityStateDescription")
    var pill = descendant(card, "activityStatePillText")
    if (!description || !pill) throw new Error("activity state presentation is not addressable")
    if (card.visualState !== "blocked-active" || description.text !== "Blocked request observed" || pill.text !== "BLOCKED REQUEST")
      throw new Error("blocked request card presented contradictory state text")
    console.log("PRIVACY_QML_ACTIVITY_CARD_STATE_OK")
    Qt.quit()
  })
}
