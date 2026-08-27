import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/privacy-audio-endpoint-delay")).replace(/^file:\/\//, "")
  property bool completed: false
  Service { id: service; audioEndpointHelperOverride: root.helper }

  function verifyLatestRefresh() {
    if (completed || service.audioEndpoints("audio-output").length !== 1) return
    if (service.audioEndpoints("microphone").length !== 1 || service.pendingAudioEndpointRefreshKind !== "")
      throw new Error("queued audio endpoint refresh did not preserve both inventories")
    completed = true
    console.log("PRIVACY_QML_AUDIO_ENDPOINT_QUEUE_OK")
    Qt.quit()
  }

  Connections {
    target: service
    function onAudioEndpointMapChanged() { root.verifyLatestRefresh() }
  }

  Timer {
    interval: 2000
    running: true
    onTriggered: { throw new Error("queued audio endpoint refresh did not complete") }
  }

  Component.onCompleted: {
    if (!service.refreshAudioEndpoints("microphone") || !service.refreshAudioEndpoints("audio-output"))
      throw new Error("valid endpoint refresh was rejected")
    if (service.pendingAudioEndpointRefreshKind !== "audio-output")
      throw new Error("busy endpoint refresh did not retain the latest request")
  }
}
