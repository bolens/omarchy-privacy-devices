pragma ComponentBehavior: Bound
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
    widget.settings = Object.assign({}, widget.settings, {
      statusMarkerMode:"letters", barMarkerPosition:"before", showBarSessionCounts:true,
      showBarActiveMarker:true, itemStatusMarkerVisibility:{microphone:true}
    })
    Qt.callLater(function() {
      var detailed = Object.assign({}, active, {
        label:"Microphone", icon:"M", apps:["<Recorder>"],
        sessions:[{id:"one"}, {id:"two"}], dependenciesReady:true, controllable:true
      })
      if (widget.barItemText(detailed) !== "A M 2")
        throw new Error("bar marker position or session count did not follow settings")
      var tooltip = widget.itemTooltip(detailed)
      if (tooltip.indexOf("＜Recorder＞") < 0 || tooltip.indexOf("Left click to mute") < 0
          || tooltip.indexOf("Middle click for microphone settings") < 0)
        throw new Error("bar tooltip lost escaped attribution or actions")
      service.settings = {enabledKinds:["microphone", "camera"]}
      service.activeSessions = [
        {id:"mic", kind:"microphone", application:"Recorder", device:"Mic", source:"pipewire", confidence:"confirmed", startedAt:1},
        {id:"cam", kind:"camera", application:"<Browser>", device:"Camera", source:"pipewire", confidence:"confirmed", startedAt:2}
      ]
      widget.settings = Object.assign({}, widget.settings, {enabledKinds:["microphone", "camera"], displayMode:"active-count"})
      Qt.callLater(function() {
        if (widget.activeCount !== 2 || widget.barText() !== "󰒃 2")
          throw new Error("active-count bar presentation did not summarize live devices")
        var summaryTooltip = widget.tooltip()
        if (summaryTooltip.indexOf("Microphone: Recorder") < 0 || summaryTooltip.indexOf("Camera: ＜Browser＞") < 0)
          throw new Error("summary tooltip lost or failed to escape live attribution")
        console.log("PRIVACY_QML_BAR_SEMANTIC_COLOR_OK")
        Qt.quit()
      })
    })
  }
}
