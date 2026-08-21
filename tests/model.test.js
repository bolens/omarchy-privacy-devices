const fs = require("fs")
const vm = require("vm")
const source = fs.readFileSync(require("path").join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const context = {}
vm.createContext(context)
vm.runInContext(source, context)

function node(mediaClass, name, extra = {}) {
  return {
    ready: true,
    isStream: true,
    properties: Object.assign({"media.class": mediaClass, "application.name": name}, extra)
  }
}

const defaults = {excludedApps: ["cava"], cameraKeywords: ["camera", "v4l2"], screenShareKeywords: ["portal", "screencast"]}
if (context.classifyNode(node("Stream/Input/Audio", "Firefox"), defaults) !== "microphone") throw new Error("microphone classification")
if (context.classifyNode(node("Stream/Output/Audio", "Firefox"), defaults) !== "audio-output") throw new Error("audio output classification")
if (context.classifyNode(node("Stream/Input/Video", "Firefox", {"media.name":"Integrated Camera"}), defaults) !== "camera") throw new Error("camera classification")
if (context.classifyNode(node("Stream/Input/Video", "Firefox", {"pipewire.access.portal":"true"}), defaults) !== "screen-share") throw new Error("screen-share classification")
if (context.classifyNode(node("Stream/Input/Audio", "cava"), defaults) !== "") throw new Error("exclusion")
if (JSON.stringify(context.unique(["Firefox", "firefox", "OBS"])) !== JSON.stringify(["Firefox", "OBS"])) throw new Error("deduplication")
if (!context.volumeMuted("Volume: 1.00 [MUTED]\n")) throw new Error("muted volume parsing")
if (context.volumeMuted("Volume: 1.00\n")) throw new Error("unmuted volume parsing")
if (!context.volumeMuted("Mute: yes\n")) throw new Error("PulseAudio muted parsing")
if (context.volumeMuted("Mute: no\n")) throw new Error("PulseAudio unmuted parsing")
if (context.volumeMuted("")) throw new Error("empty volume parsing")
if (!context.hasVolumeState("Mute: no\n")) throw new Error("PulseAudio state recognition")
if (!context.hasVolumeState("Volume: 1.00\n")) throw new Error("PipeWire state recognition")
if (context.hasVolumeState("")) throw new Error("empty state recognition")
if (!context.mutedFromExitCode(10, false)) throw new Error("muted exit state")
if (context.mutedFromExitCode(11, true)) throw new Error("unmuted exit state")
if (!context.mutedFromExitCode(12, true)) throw new Error("failed probe preserves state")
if (context.shouldAcceptControlProbe("camera", "camera")) throw new Error("pending probe rejection")
if (!context.shouldAcceptControlProbe("location", "camera")) throw new Error("unrelated probe acceptance")
console.log("model tests passed")
