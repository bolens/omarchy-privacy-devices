const fs = require("fs")
const path = require("path")

const root = path.join(__dirname, "..")
const read = file => fs.readFileSync(path.join(root, file), "utf8")

const bar = read("BarWidget.qml")
const service = read("Service.qml")
const control = read("privacy-control")
const recording = read("privacy-recording")
const manifest = read("manifest.json")

if (!bar.includes("textFormat: Text.PlainText")) throw new Error("plain-text QML enforcement missing")
if (!bar.includes("Model.autoTextSafe(value)")) throw new Error("shared AutoText boundary missing")
if (!service.includes("Model.autoTextSafe(body)")) throw new Error("notification markup boundary missing")

if (/cameraModule|cameraKernelModule|modprobe/.test(control + manifest + service))
  throw new Error("configurable privileged kernel-module surface restored")

if (/\bpkill\b|\/tmp\//.test(recording)) throw new Error("broad or shared-temp process control restored")
for (const required of ["XDG_RUNTIME_DIR", "/proc/$pid/status", "/proc/$pid/exe", "kill -INT"])
  if (!recording.includes(required)) throw new Error(`recorder identity check missing: ${required}`)

console.log("security tests passed")
