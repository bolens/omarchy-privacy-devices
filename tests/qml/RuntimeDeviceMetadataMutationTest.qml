import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var commits: []
  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, settings) { root.acceptCommit(settings) }
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
    settings: ({enabledKinds:[],historyEnabled:false,deviceLabels:{},icons:{},itemLabels:{}})
  }

  function acceptCommit(settings) {
    root.commits = root.commits.concat([settings])
    if (root.commits.length === 1) {
      if (settings.deviceLabels["alsa_input.desk"] !== "Desk microphone"
          || settings.deviceLabels["alsa_input.webcam"] !== "Webcam microphone"
          || settings.icons.microphone !== "M" || settings.icons.camera !== "C"
          || settings.itemLabels.microphone !== "Mic" || settings.itemLabels.camera !== "Webcam")
        throw new Error("coalesced device metadata lost a sibling edit")
      widget.persistDeviceLabel("alsa_input.desk", "alsa_input.desk")
      widget.persistLabel("microphone", "")
      return
    }
    if (root.commits.length !== 2 || settings.deviceLabels["alsa_input.desk"] !== undefined
        || settings.itemLabels.microphone !== undefined
        || settings.deviceLabels["alsa_input.webcam"] !== "Webcam microphone" || settings.itemLabels.camera !== "Webcam")
      throw new Error("metadata inheritance removed unrelated device values")
    console.log("PRIVACY_QML_DEVICE_METADATA_MUTATION_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.persistDeviceLabel("alsa_input.desk", "Desk microphone")
    widget.persistDeviceLabel("alsa_input.webcam", "Webcam microphone")
    widget.persistIcon("microphone", "M")
    widget.persistIcon("camera", "C")
    widget.persistLabel("microphone", "Mic")
    widget.persistLabel("camera", "Webcam")
  }

  Timer { interval: 1500; running: true; onTriggered: { throw new Error("device metadata commits did not complete") } }
}
