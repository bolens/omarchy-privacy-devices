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
const manifest = read("manifest.json")

if (!bar.includes("textFormat: Text.PlainText")) throw new Error("plain-text QML enforcement missing")
if (!bar.includes("Model.autoTextSafe(value)")) throw new Error("shared AutoText boundary missing")
if (!service.includes("Model.autoTextSafe(body)")) throw new Error("notification markup boundary missing")

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
if (/window.title|commandLine|cmdline/.test(history)) throw new Error("history stores unnecessarily sensitive metadata")

console.log("security tests passed")
