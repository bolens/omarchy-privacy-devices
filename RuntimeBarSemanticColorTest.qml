import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root

  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, _settings) {}
  }
  QtObject {
    id: barMock
    property var shell: shellMock
    property color barForeground: "#eeeeee"
    property color foreground: "#eeeeee"
    property color urgent: "#ff3333"
    property string fontFamily: "sans-serif"
    property bool foregroundAnimationEnabled: false
    property string activePopout: ""
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
      enabledKinds: [], activeColorRole: "accent", inactiveColorRole: "foreground",
      disabledColorRole: "muted", blockedActiveColorRole: "urgent",
      itemColorRoles: {microphone:{unmuted:"urgent"}}
    })
  }

  function colorName(value) { return String(value).toLowerCase() }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    var base = {kind:"microphone",pending:false,health:{status:"healthy"}}
    var active = Object.assign({}, base, {active:true,controlEnabled:true})
    var idle = Object.assign({}, base, {active:false,controlEnabled:true})
    var disabled = Object.assign({}, base, {active:false,controlEnabled:false})
    var blocked = Object.assign({}, base, {active:true,controlEnabled:false})
    if (colorName(widget.itemColor(active)) !== colorName(Color.accent))
      throw new Error("legacy microphone unmuted role shadowed the global active color")
    if (colorName(widget.itemColor(idle)) !== colorName(barMock.foreground))
      throw new Error("idle device did not use the global foreground role")
    if (colorName(widget.itemColor(disabled)) !== colorName(Color.muted))
      throw new Error("disabled device did not use the global muted role")
    if (widget.itemVisualState(blocked) !== "blocked-active" || colorName(widget.itemColor(blocked)) !== colorName(Color.urgent))
      throw new Error("observable blocked request did not use the urgent semantic state")
    console.log("PRIVACY_QML_BAR_SEMANTIC_COLOR_OK")
    Qt.quit()
  }
}
