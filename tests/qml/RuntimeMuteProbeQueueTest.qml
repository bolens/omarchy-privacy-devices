import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/privacy-audio-state-delay")).replace(/^file:\/\//, "")
  property bool sawMicrophoneDrain: false
  property bool sawOutputDrain: false
  Service { id: service; audioStateHelperOverride: root.helper }

  function verifySettled() {
    if (service.microphoneStateBusy || service.outputStateBusy
        || service.microphoneStatePending || service.outputStatePending) return
    if (!sawMicrophoneDrain || !sawOutputDrain) return
    if (!service.microphoneMuted || service.outputMuted)
      throw new Error("serialized audio probes lost their final observed states")
    console.log("PRIVACY_QML_MUTE_PROBE_QUEUE_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.settings = {enabledKinds:["microphone", "audio-output"]}
    service.refreshMuteState()
    if (!service.microphoneStateBusy || !service.outputStateBusy)
      throw new Error("audio probes did not claim synchronous ownership")
    service.refreshMuteState()
    if (!service.microphoneStatePending || !service.outputStatePending)
      throw new Error("busy audio probes did not retain a final refresh")
  }

  Connections {
    target: service
    function onMicrophoneStatePendingChanged() {
      if (!service.microphoneStatePending) root.sawMicrophoneDrain = true
      Qt.callLater(root.verifySettled)
    }
    function onOutputStatePendingChanged() {
      if (!service.outputStatePending) root.sawOutputDrain = true
      Qt.callLater(root.verifySettled)
    }
    function onMicrophoneStateBusyChanged() { Qt.callLater(root.verifySettled) }
    function onOutputStateBusyChanged() { Qt.callLater(root.verifySettled) }
  }
  Timer { interval: 2000; running: true; onTriggered: { throw new Error("audio probe queue did not settle") } }
}
