pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons
import "Model.js" as Model
// Imported JavaScript namespaces are valid here but Qt treats nested test objects as unqualified.
// qmllint disable unqualified

ShellRoot {
  id: root
  property var toggles: []

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
    function itemSessionCount(_entry) { return 0 }
    function itemStateLabel(entry) { return Model.privacyStateLabel(entry) }
    function deviceLabel(value) { return value }
    function isAudioControl(_entry) { return false }
    function toggleEntry(entry) { root.toggles = root.toggles.concat([entry.kind]) }
    function addPolicyValue(_key, _value) {}
  }

  PrivacyActivityCard {
    id: card
    width: 500
    controller: controllerMock
    entry: ({kind:"screenshot",label:"Screenshot",icon:"S",active:false,apps:[],sessions:[],controllable:true,controlEnabled:true,pending:false,dependenciesReady:true,health:{status:"healthy",summary:""}})
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
    var clickArea = descendant(card, "activityCardClickArea")
    if (!clickArea) throw new Error("activity card click target is not addressable")
    card.activate(Qt.LeftButton)
    if (root.toggles.length !== 0) throw new Error("screenshot card activated its hidden control")
    card.activate(Qt.MiddleButton)
    if (controllerMock.editingKind !== "screenshot") throw new Error("middle click did not open device settings")
    card.entry = {kind:"location",label:"Location",icon:"L",active:false,apps:[],sessions:[],controllable:true,controlEnabled:false,pending:false,dependenciesReady:false,health:{status:"unavailable",summary:"Install support"}}
    card.activate(Qt.LeftButton)
    card.entry = {kind:"camera",label:"Camera",icon:"C",active:false,apps:[],sessions:[],controllable:true,controlEnabled:true,pending:true,dependenciesReady:true,health:{status:"healthy",summary:""}}
    card.activate(Qt.LeftButton)
    if (root.toggles.length !== 0) throw new Error("unavailable or pending card activated its control")
    card.entry = {kind:"camera",label:"Camera",icon:"C",active:false,apps:[],sessions:[],controllable:true,controlEnabled:true,pending:false,dependenciesReady:true,health:{status:"healthy",summary:""}}
    card.activate(Qt.LeftButton)
    if (root.toggles.join("|") !== "camera" || controllerMock.selectedKind !== "camera")
      throw new Error("available card did not dispatch its control")
    console.log("PRIVACY_QML_ACTIVITY_CARD_INTERACTION_OK")
    Qt.quit()
  })
}
