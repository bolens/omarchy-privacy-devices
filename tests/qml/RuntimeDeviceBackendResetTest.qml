import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var commits: []
  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, settings) {
      root.commits = root.commits.concat([settings])
      if (root.commits.length !== 1) throw new Error("backend resets were not coalesced")
      if (settings.screenshotBackend !== "omarchy" || settings.screenshotCustomCommand !== "" || settings.screenshotProcessName !== ""
          || settings.recordingBackend !== "omarchy" || settings.recordingProcessName !== ""
          || settings.recordingCustomStartCommand !== "" || settings.recordingCustomStopCommand !== ""
          || settings.audioControlBackend !== "auto")
        throw new Error("device backend reset did not restore complete defaults")
      if (Object.keys(widget.deviceBackendDefaults("camera")).length !== 0)
        throw new Error("unsupported device unexpectedly received backend defaults")
      console.log("PRIVACY_QML_DEVICE_BACKEND_RESET_OK")
      Qt.quit()
    }
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
    settings: ({enabledKinds:[],historyEnabled:false,screenshotBackend:"grim",recordingBackend:"wf-recorder",audioControlBackend:"wpctl"})
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.persistSettings({screenshotBackend:"custom",screenshotCustomCommand:"capture-now",screenshotProcessName:"capture-proc"})
    widget.resetDeviceBackend("screenshot")
    widget.resetDeviceBackend("screen-recording")
    widget.resetDeviceBackend("microphone")
  }

  Timer { interval: 1500; running: true; onTriggered: { throw new Error("backend reset commit did not complete") } }
}
