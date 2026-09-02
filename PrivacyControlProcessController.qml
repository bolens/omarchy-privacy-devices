pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: controller
  required property var host

  readonly property bool microphoneStateRunning: microphoneStateProcess.running
  readonly property bool outputStateRunning: outputStateProcess.running
  readonly property bool microphoneControlRunning: microphoneControlProcess.running
  readonly property bool outputControlRunning: outputControlProcess.running
  readonly property bool preventativeStateRunning: privacyStateProcess.running
  readonly property bool preventativeControlRunning: privacyControlProcess.running

  function startAudioState(kind, command) {
    var process = kind === "microphone" ? microphoneStateProcess : outputStateProcess
    process.command = command
    process.running = true
  }

  function startAudioControl(kind, command) {
    var process = kind === "microphone" ? microphoneControlProcess : outputControlProcess
    process.command = command
    process.running = true
  }

  function stopPreventativeState() { privacyStateProcess.running = false }
  function startPreventativeState(command) { privacyStateProcess.command = command; privacyStateProcess.running = true }
  function startPreventativeControl(command) { privacyControlProcess.command = command; privacyControlProcess.running = true }

  Process {
    id: microphoneStateProcess
    onExited: function(exitCode) {
      controller.host.setResult("probe", "microphone", exitCode)
      controller.host.fallbackMicrophoneMuted = Model.mutedFromExitCode(exitCode, controller.host.fallbackMicrophoneMuted)
      controller.host.verifyControlTransaction("microphone", !controller.host.fallbackMicrophoneMuted, exitCode === 10 || exitCode === 11)
      controller.host.microphoneStateBusy = false
      if (controller.host.microphoneStatePending) controller.host.refreshAudioState("microphone")
    }
  }

  Process {
    id: outputStateProcess
    onExited: function(exitCode) {
      controller.host.setResult("probe", "audio-output", exitCode)
      controller.host.fallbackOutputMuted = Model.mutedFromExitCode(exitCode, controller.host.fallbackOutputMuted)
      controller.host.verifyControlTransaction("audio-output", !controller.host.fallbackOutputMuted, exitCode === 10 || exitCode === 11)
      controller.host.outputStateBusy = false
      if (controller.host.outputStatePending) controller.host.refreshAudioState("audio-output")
    }
  }

  Process {
    id: microphoneControlProcess
    onExited: function(exitCode) {
      controller.host.setResult("control", "microphone", exitCode)
      controller.host.beginControlVerification("microphone", exitCode)
      controller.host.refreshMuteState()
    }
  }

  Process {
    id: outputControlProcess
    onExited: function(exitCode) {
      controller.host.setResult("control", "audio-output", exitCode)
      controller.host.beginControlVerification("audio-output", exitCode)
      controller.host.refreshMuteState()
    }
  }

  Process {
    id: privacyStateProcess
    onExited: function(exitCode) {
      controller.host.setResult("probe", controller.host.privacyStateKind, exitCode)
      if (Model.shouldAcceptControlProbe(controller.host.privacyStateKind, controller.host.privacyControlKind)) {
        controller.host.setAllowed(controller.host.privacyStateKind, Model.mutedFromExitCode(exitCode, controller.host.controlEnabled(controller.host.privacyStateKind)))
        controller.host.verifyControlTransaction(controller.host.privacyStateKind, controller.host.controlEnabled(controller.host.privacyStateKind), exitCode === 10 || exitCode === 11)
      }
      controller.host.privacyStateBusy = false
      controller.host.runNextPrivacyState()
    }
  }

  Process {
    id: privacyControlProcess
    onExited: function(exitCode) {
      var kind = controller.host.privacyControlKind
      controller.host.setResult("control", kind, exitCode)
      controller.host.beginControlVerification(kind, exitCode)
      controller.host.privacyControlKind = ""
      controller.host.refreshPreventativeControls()
    }
  }
}
