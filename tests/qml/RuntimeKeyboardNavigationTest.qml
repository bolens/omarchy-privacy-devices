pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root

  function fixtureEntry(kind) {
    return {
      kind:kind, label:kind, icon:"X", active:false, apps:[], sessions:[],
      controllable:true, controlEnabled:true, pending:false, dependenciesReady:true,
      health:{status:"healthy", summary:""}
    }
  }
  Service { id: sharedService }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? sharedService : null }
    function updateEntryInline(_id, _settings) {}
  }
  QtObject {
    id: barMock
    property var shell: shellMock
    property color barForeground: "#ffffff"
    property color foreground: "#ffffff"
    property color urgent: "#ff5555"
    property string fontFamily: "sans-serif"
    property bool foregroundAnimationEnabled: false
    property var activePopout: ""
    property bool vertical: false
    property int barSize: 40
    property string position: "top"
    property var screen: null
    function switchPanelFrom(_owner, _direction) { return false }
    function requestPopout(key) { activePopout = key }
    function releasePopout(key) { if (activePopout === key) activePopout = "" }
    function registerClickTarget(_item) {}
    function unregisterClickTarget(_item) {}
    function showTooltip(_item, _text) {}
    function hideTooltip(_item) {}
  }

  BarWidget {
    id: widget
    bar: barMock
    settings: ({
      enabledKinds:["camera", "microphone", "location"],
      order:["camera", "microphone", "location"],
      showIdle:true,
      showControls:true
    })
  }

  Component.onCompleted: Qt.callLater(function() {
    widget.displayedActivityItems = [root.fixtureEntry("camera"), root.fixtureEntry("microphone"), root.fixtureEntry("location")]
    widget.selectedKind = ""
    widget.moveActivitySelection(1)
    if (widget.selectedKind !== "camera") throw new Error("keyboard selection did not start at the first item")
    widget.moveActivitySelection(-1)
    if (widget.selectedKind !== "camera") throw new Error("keyboard selection crossed the lower boundary")
    widget.moveActivitySelection(1)
    widget.moveActivitySelection(1)
    widget.moveActivitySelection(1)
    if (widget.selectedKind !== "location") throw new Error("keyboard selection crossed the upper boundary")

    widget.showingGlobalSettings = true
    widget.showingHistory = true
    widget.activateActivitySelection()
    if (widget.editingKind !== "location" || widget.showingGlobalSettings || widget.showingHistory)
      throw new Error("keyboard activation did not enter the selected device")
    widget.moveDeviceEditor(-1)
    if (widget.editingKind !== "microphone" || widget.selectedKind !== "microphone")
      throw new Error("device keyboard navigation did not move in configured order")
    widget.moveDeviceEditor(1)
    if (widget.editingKind !== "location") throw new Error("device keyboard navigation did not advance")
    widget.moveDeviceEditor(1)
    if (widget.editingKind !== "location") throw new Error("device keyboard navigation crossed the upper boundary")

    widget.open()
    widget.closeCurrentLayer()
    if (widget.editingKind !== "" || !widget.opened)
      throw new Error("device dismissal closed the entire popup")
    widget.showingGlobalSettings = true
    widget.closeCurrentLayer()
    if (widget.showingGlobalSettings || !widget.opened)
      throw new Error("settings dismissal closed the entire popup")
    widget.showingHistory = true
    widget.closeCurrentLayer()
    if (widget.showingHistory || !widget.opened)
      throw new Error("history dismissal closed the entire popup")
    widget.closeCurrentLayer()
    if (widget.opened) throw new Error("top-level dismissal left the popup open")

    console.log("PRIVACY_QML_KEYBOARD_NAVIGATION_OK")
    Qt.quit()
  })
}
