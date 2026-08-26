const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const root = path.join(__dirname, "..")
const fingerprint = path.join(root, "scripts", "capture-plugin-fingerprint")
const prune = path.join(root, "scripts", "prune-capture-recovery")
const guard = path.join(root, "scripts", "capture-environment-guard")
const postconditions = path.join(root, "scripts", "verify-capture-postconditions")
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-capture-safety-"))
function execute(script, args, env = {}) {
  return spawnSync(script, args, { encoding: "utf8", env: { ...process.env, ...env } })
}
function run(script, args, env = {}) {
  const result = execute(script, args, env)
  assert.equal(result.status, 0, result.stderr)
  return result.stdout
}

try {
  const plugin = path.join(temporary, "plugin")
  fs.mkdirSync(path.join(plugin, "tests"), { recursive: true })
  fs.writeFileSync(path.join(plugin, "BarWidget.qml"), "Item {}\n")
  fs.writeFileSync(path.join(plugin, "plugin.json"), "{}\n")
  fs.writeFileSync(path.join(plugin, "tests", "contracts.js"), "one\n")
  fs.writeFileSync(path.join(plugin, "RuntimeModelTest.qml"), "one\n")
  const before = run(fingerprint, [plugin])
  fs.writeFileSync(path.join(plugin, "tests", "contracts.js"), "two\n")
  fs.writeFileSync(path.join(plugin, "RuntimeModelTest.qml"), "two\n")
  assert.equal(run(fingerprint, [plugin]), before,
    "test-only changes must not invalidate a capture")
  fs.writeFileSync(path.join(plugin, "BarWidget.qml"), "Item { visible: false }\n")
  assert.notEqual(run(fingerprint, [plugin]), before,
    "runtime QML changes must invalidate a capture")

  const recovery = path.join(temporary, "captures")
  const oldCapture = path.join(recovery, "capture.old")
  const recentCapture = path.join(recovery, "capture.recent")
  const unrelated = path.join(recovery, "keep-me")
  for (const directory of [oldCapture, recentCapture, unrelated]) fs.mkdirSync(directory, { recursive: true })
  const old = new Date(Date.now() - 10 * 86400 * 1000)
  fs.utimesSync(oldCapture, old, old)
  fs.utimesSync(unrelated, old, old)
  run(prune, [recovery, "7"])
  assert.equal(fs.existsSync(oldCapture), false, "expired capture recovery must be pruned")
  assert.equal(fs.existsSync(recentCapture), true, "recent recovery must be retained")
  assert.equal(fs.existsSync(unrelated), true, "unrelated directories must never be pruned")

  const qs = path.join(temporary, "qs")
  const hyprctl = path.join(temporary, "hyprctl")
  const historyCommand = path.join(temporary, "privacy-history")
  fs.writeFileSync(qs, `#!/usr/bin/env bash
[[ $MOCK_SHELL == down ]] && exit 1
[[ $6 == renew && $MOCK_LEASE == lost ]] && printf 'denied\\n' || { [[ $6 == ping ]] && printf 'ok\\n' || { [[ $6 == isDnd ]] && printf '%s\\n' "$MOCK_DND" || printf 'ok\\n'; }; }
`)
  fs.writeFileSync(hyprctl, `#!/usr/bin/env bash
printf '[{"name":"DP-1","focused":%s,"activeWorkspace":{"id":%s}}]\\n' "$MOCK_FOCUSED" "$MOCK_WORKSPACE"
`)
  fs.writeFileSync(historyCommand, `#!/usr/bin/env bash
cat "$MOCK_HISTORY"
`)
  for (const file of [qs, hyprctl, historyCommand]) fs.chmodSync(file, 0o755)
  const baseline = run(fingerprint, [plugin]).trim()
  const guardArgs = ["101", "owner-token-abcdefghijklmnop", plugin, baseline, "true"]
  const guardEnv = { PRIVACY_QS_COMMAND: qs, MOCK_SHELL: "up", MOCK_LEASE: "ok" }
  run(guard, guardArgs, guardEnv)
  assert.match(execute(guard, guardArgs, { ...guardEnv, MOCK_SHELL: "down" }).stderr, /Shell changed/)
  assert.match(execute(guard, guardArgs, { ...guardEnv, MOCK_LEASE: "lost" }).stderr, /lease was lost/)
  fs.writeFileSync(path.join(plugin, "BarWidget.qml"), "Item { opacity: 0.5 }\n")
  assert.match(execute(guard, guardArgs, guardEnv).stderr, /runtime files changed/)

  const settings = path.join(temporary, "settings.json")
  const settingsSnapshot = path.join(temporary, "settings-snapshot.json")
  const historySnapshot = path.join(temporary, "history.json")
  fs.writeFileSync(settings, "{}\n")
  fs.writeFileSync(settingsSnapshot, "{}\n")
  fs.writeFileSync(historySnapshot, "[]\n")
  const postArgs = [settingsSnapshot, settings, historySnapshot, "DP-1", "4", "101", "101", "off"]
  const postEnv = { PRIVACY_QS_COMMAND: qs, PRIVACY_HYPRCTL_COMMAND: hyprctl,
    PRIVACY_HISTORY_COMMAND: historyCommand, MOCK_HISTORY: historySnapshot, MOCK_SHELL: "up",
    MOCK_LEASE: "ok", MOCK_DND: "off", MOCK_FOCUSED: "true", MOCK_WORKSPACE: "4" }
  run(postconditions, postArgs, postEnv)
  assert.match(execute(postconditions, postArgs, { ...postEnv, MOCK_DND: "on" }).stderr, /DND state/)
  assert.match(execute(postconditions, postArgs, { ...postEnv, MOCK_WORKSPACE: "5" }).stderr, /workspace/)
  assert.match(execute(postconditions, [...postArgs.slice(0, 6), "202", "off"], postEnv).stderr, /PID changed/)
} finally {
  fs.rmSync(temporary, { recursive: true, force: true })
}
