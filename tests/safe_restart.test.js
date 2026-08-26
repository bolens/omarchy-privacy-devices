const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const root = path.join(__dirname, "..")
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-safe-restart-"))
try {
  const state = path.join(temporary, "state")
  const settings = path.join(temporary, "shell.json")
  const history = path.join(temporary, "history")
  fs.writeFileSync(state, "old")
  fs.writeFileSync(settings, '{"untouched":true}\n')
  fs.writeFileSync(history, '[]\n')
  const qs = path.join(temporary, "qs")
  const hyprctl = path.join(temporary, "hyprctl")
  const historyCommand = path.join(temporary, "privacy-history")
  fs.writeFileSync(qs, `#!/usr/bin/env bash
case "$1" in
  list) case "$(<"$MOCK_STATE")" in old) printf 'Process ID: 101\\n';; new) printf 'Process ID: 202\\n';; stopped) [[ "\${MOCK_AUTO:-}" == 1 ]] && { printf 'new' >"$MOCK_STATE"; printf 'Process ID: 202\\n'; };; esac ;;
  ipc) [[ $3 == 101 || $3 == 202 ]] || exit 1; [[ $6 == ping ]] && printf 'ok\\n' || printf 'true\\n' ;;
  kill) [[ $3 == 101 ]] || exit 1; printf 'stopped' >"$MOCK_STATE" ;;
esac
`)
  fs.writeFileSync(hyprctl, `#!/usr/bin/env bash
[[ $(<"$MOCK_STATE") == stopped ]] || { printf 'replacement launched before old shell exited\\n' >&2; exit 1; }
printf 'new' >"$MOCK_STATE"
`)
  fs.writeFileSync(historyCommand, `#!/usr/bin/env bash
[[ $1 == load ]] && cat "$MOCK_HISTORY"
`)
  for (const file of [qs, hyprctl, historyCommand]) fs.chmodSync(file, 0o755)
  const result = spawnSync(path.join(root, "scripts", "restart-shell-safely"), [], {
    encoding: "utf8",
    env: { ...process.env, MOCK_STATE: state, MOCK_HISTORY: history, PRIVACY_QS_COMMAND: qs,
      PRIVACY_HYPRCTL_COMMAND: hyprctl, PRIVACY_HISTORY_COMMAND: historyCommand, PRIVACY_SETTINGS_FILE: settings },
  })
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /101 -> 202/)
  assert.equal(fs.readFileSync(settings, "utf8"), '{"untouched":true}\n')
  assert.equal(fs.readFileSync(history, "utf8"), '[]\n')
  fs.writeFileSync(state, "old")
  const automatic = spawnSync(path.join(root, "scripts", "restart-shell-safely"), [], {
    encoding: "utf8",
    env: { ...process.env, MOCK_AUTO: "1", MOCK_STATE: state, MOCK_HISTORY: history,
      PRIVACY_QS_COMMAND: qs, PRIVACY_HYPRCTL_COMMAND: hyprctl,
      PRIVACY_HISTORY_COMMAND: historyCommand, PRIVACY_SETTINGS_FILE: settings },
  })
  assert.equal(automatic.status, 0, automatic.stderr)
  assert.match(automatic.stdout, /101 -> 202/)
} finally {
  fs.rmSync(temporary, { recursive: true, force: true })
}
