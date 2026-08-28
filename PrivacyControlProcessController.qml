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
      host.setResult("probe", "microphone", exitCode)
      host.fallbackMicrophoneMuted = Model.mutedFromExitCode(exitCode, host.fallbackMicrophoneMuted)
      host.verifyControlTransaction("microphone", !host.fallbackMicrophoneMuted, exitCode === 10 || exitCode === 11)
      host.microphoneStateBusy = false
      if (host.microphoneStatePending) host.refreshAudioState("microphone")
    }
  }

  Process {
    id: outputStateProcess
    onExited: function(exitCode) {
      host.setResult("probe", "audio-output", exitCode)
      host.fallbackOutputMuted = Model.mutedFromExitCode(exitCode, host.fallbackOutputMuted)
      host.verifyControlTransaction("audio-output", !host.fallbackOutputMuted, exitCode === 10 || exitCode === 11)
      host.outputStateBusy = false
      if (host.outputStatePending) host.refreshAudioState("audio-output")
    }
  }

  Process {
    id: microphoneControlProcess
    onExited: function(exitCode) {
      host.setResult("control", "microphone", exitCode)
      host.beginControlVerification("microphone", exitCode)
      host.refreshMuteState()
    }
  }

  Process {
    id: outputControlProcess
    onExited: function(exitCode) {
      host.setResult("control", "audio-output", exitCode)
      host.beginControlVerification("audio-output", exitCode)
      host.refreshMuteState()
    }
  }

  Process {
    id: privacyStateProcess
    onExited: function(exitCode) {
      host.setResult("probe", host.privacyStateKind, exitCode)
      if (Model.shouldAcceptControlProbe(host.privacyStateKind, host.privacyControlKind)) {
        host.setAllowed(host.privacyStateKind, Model.mutedFromExitCode(exitCode, host.controlEnabled(host.privacyStateKind)))
        host.verifyControlTransaction(host.privacyStateKind, host.controlEnabled(host.privacyStateKind), exitCode === 10 || exitCode === 11)
      }
      host.privacyStateBusy = false
      host.runNextPrivacyState()
    }
  }

  Process {
    id: privacyControlProcess
    onExited: function(exitCode) {
      var kind = host.privacyControlKind
      host.setResult("control", kind, exitCode)
      host.beginControlVerification(kind, exitCode)
      host.privacyControlKind = ""
      host.refreshPreventativeControls()
    }
  }
}
