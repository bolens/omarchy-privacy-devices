import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {audioControlBackend:"pactl", recordingBackend:"wf-recorder", screenshotBackend:"grim-satty"}
    if (JSON.stringify(service.audioToggleCommand("microphone")) !== JSON.stringify(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])
        || JSON.stringify(service.audioToggleCommand("audio-output")) !== JSON.stringify(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]))
      throw new Error("pactl toggle command selected the wrong target")
    var pactlProbe = service.audioStateCommand("microphone")
    if (pactlProbe.length !== 3 || pactlProbe[0] !== "sh" || pactlProbe[1] !== "-c"
        || pactlProbe[2].indexOf("pactl get-source-mute @DEFAULT_SOURCE@") < 0)
      throw new Error("pactl state command selected the wrong probe")

    service.settings = {audioControlBackend:"wpctl", recordingBackend:"gpu-screen-recorder", screenshotBackend:"hyprshot"}
    if (JSON.stringify(service.audioToggleCommand("audio-output")) !== JSON.stringify(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]))
      throw new Error("wpctl toggle command selected the wrong target")
    var wpctlProbe = service.audioStateCommand("microphone")
    if (wpctlProbe[2].indexOf("wpctl get-volume @DEFAULT_AUDIO_SOURCE@") < 0)
      throw new Error("wpctl state command selected the wrong probe")

    service.settings = {audioControlBackend:"invalid", recordingBackend:"invalid", screenshotBackend:"invalid"}
    var automatic = service.audioToggleCommand("microphone")
    if (service.audioControlBackend() !== "auto" || service.recordingBackend() !== "omarchy" || service.screenshotBackend() !== "omarchy"
        || automatic[0] !== "sh" || automatic[2].indexOf("command -v pactl") < 0 || automatic[2].indexOf("exec wpctl") < 0)
      throw new Error("invalid backend settings did not fall back safely")
    if (service.backendFor("microphone").indexOf("Audio control: auto") !== 0
        || service.backendFor("screen-recording") !== "Recorder process detection (omarchy)"
        || service.backendFor("screenshot") !== "Screenshot capture (omarchy)")
      throw new Error("backend diagnostics diverged from command selection")

    console.log("PRIVACY_QML_BACKEND_COMMAND_SELECTION_OK")
    Qt.quit()
  }
}
