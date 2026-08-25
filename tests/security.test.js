const fs = require("fs")
const path = require("path")

const root = path.join(__dirname, "..")
const read = file => fs.readFileSync(path.join(root, file), "utf8")

const bar = read("BarWidget.qml")
const service = read("Service.qml")
const control = read("privacy-control")
const recording = read("privacy-recording")
const observer = read("privacy-observe")
const history = read("privacy-history")
const diagnostics = read("privacy-diagnostics")
const manifest = read("manifest.json")
const workflowsDirectory = path.join(root, ".github", "workflows")

if (!bar.includes("textFormat: Text.PlainText")) throw new Error("plain-text QML enforcement missing")
if (!bar.includes("Model.autoTextSafe(value)")) throw new Error("shared AutoText boundary missing")
if (!service.includes("Model.autoTextSafe(body)")) throw new Error("notification markup boundary missing")

const shellRunCalls = [...bar.matchAll(/bar\.run\(([^\n]+)\)/g)].map(match => match[1].trim())
if (shellRunCalls.length !== 2 || !shellRunCalls.every(call => call === "command" || call === "screenshotCommand"))
  throw new Error("only explicit user custom commands may cross the bar shell-string boundary")
for (const required of [
  '[recordingHelper, entry.controlEnabled ? "stop" : "start", "wf-recorder"]',
  '["omarchy-capture-screenrecording", "--stop-recording"]',
  '["omarchy-menu", "toggle", "trigger.capture.screenrecord"]',
  '["omarchy-capture-screenshot"]',
  '[screenshotHelper, "capture", screenshotBackend]',
])
  if (!bar.includes(`Quickshell.execDetached(${required})`)) throw new Error(`argument-safe capture launch missing: ${required}`)

if (/cameraModule|cameraKernelModule|modprobe/.test(control + manifest + service))
  throw new Error("configurable privileged kernel-module surface restored")

if (/\bpkill\b|\/tmp\//.test(recording)) throw new Error("broad or shared-temp process control restored")
for (const required of ["XDG_RUNTIME_DIR", "/proc/$pid/status", "/proc/$pid/exe", "kill -INT"])
  if (!recording.includes(required)) throw new Error(`recorder identity check missing: ${required}`)

for (const forbidden of ["socket", "requests", "urllib", "subprocess", "os.system"])
  if (observer.includes(forbidden)) throw new Error(`direct observer gained network or command execution surface: ${forbidden}`)
for (const required of ["os.getuid()", "process.stat().st_uid", "os.readlink", "ALSA_CAPTURE", "CAMERA"])
  if (!observer.includes(required)) throw new Error(`direct observer boundary missing: ${required}`)

for (const required of ["FIELDS =", "MAX_ENTRIES = 100", "MAX_AGE_MS", "0o700", "0o600", "temporary.replace(path)"])
  if (!history.includes(required)) throw new Error(`private bounded history invariant missing: ${required}`)
if (!history.includes("TEXT_CONTROLS.sub")) throw new Error("persisted history text sanitation missing")
if (/window.title|commandLine|cmdline/.test(history)) throw new Error("history stores unnecessarily sensitive metadata")
if (!/subprocess\.run\([\s\S]*?timeout=5/.test(diagnostics)) throw new Error("clipboard subprocess timeout missing")

for (const workflowName of fs.readdirSync(workflowsDirectory)) {
  const workflow = read(path.join(".github", "workflows", workflowName))
  for (const match of workflow.matchAll(/^\s*uses:\s*([^\s#]+)(?:\s+#.*)?$/gm)) {
    const reference = match[1]
    if (reference.startsWith("./")) continue
    if (!/@[0-9a-f]{40}$/i.test(reference))
      throw new Error(`external action is not pinned to a full commit SHA: ${workflowName}: ${reference}`)
  }
}

console.log("security tests passed")
