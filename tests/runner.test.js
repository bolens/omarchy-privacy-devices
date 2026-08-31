const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const root = path.join(__dirname, "..")
const runnerPath = path.join(__dirname, "run_all.sh")
const runner = fs.existsSync(runnerPath) ? fs.readFileSync(runnerPath, "utf8") : ""
const ci = fs.readFileSync(path.join(root, ".github", "workflows", "ci.yml"), "utf8")
const testing = fs.readFileSync(path.join(root, "TESTING.md"), "utf8")
const packageJson = JSON.parse(fs.readFileSync(path.join(root, "package.json"), "utf8"))
const qmlLintPath = path.join(root, "scripts", "lint-qml")
assert.ok(fs.existsSync(qmlLintPath), "one shared QML lint entry point must exist")
const qmlLint = fs.readFileSync(qmlLintPath, "utf8")
const live = fs.readFileSync(path.join(root, "scripts", "verify-live"), "utf8")

assert.match(runner, /for test_file in tests\/\*\.test\.js/, "the canonical runner must discover every JavaScript suite")
assert.match(runner, /python3 -m unittest discover -s tests -p 'test_\*\.py'/, "the canonical runner must discover every Python suite")
for (const helper of ["privacy-audio-devices", "privacy-diagnostics", "privacy-history", "privacy-location", "privacy-menu-entry", "privacy-observe", "privacy-settings"])
  assert.match(runner, new RegExp(`python3 -m py_compile[^\\n]*${helper}`), `the canonical runner must compile ${helper}`)
assert.match(runner, /shellcheck[\s\S]*?privacy-control[\s\S]*?tests\/run_qml_runtime\.sh[\s\S]*?tests\/fixtures\/\*/, "the canonical runner must lint runtime, maintainer, and fixture shell scripts")
assert.match(runner, /runtime_mode=\$\{PRIVACY_RUNTIME_TESTS:-auto\}/, "the canonical runner must expose one runtime-QML mode switch")
assert.match(runner, /tests\/run_qml_runtime\.sh/, "the canonical runner must be able to execute the runtime QML suite")
assert.match(runner, /PRIVACY_RUNTIME_TESTS must be auto, always, or never/, "the canonical runner must reject invalid runtime modes")
for (const helper of ["privacy-action", "scripts/build-site.sh"])
  assert.match(runner, new RegExp(`shellcheck[\\s\\S]*?${helper.replace(".", "\\.")}`), `the canonical runner must lint ${helper}`)
assert.match(ci, /name: Run behavior suite[\s\S]*?run: tests\/run_all\.sh/, "CI must delegate the behavior suite to the canonical runner")
const pluginJob = ci.slice(ci.indexOf("\n  plugin:\n"), ci.indexOf("\n  repository:\n"))
assert.ok(pluginJob.indexOf("run: npm ci") >= 0 && pluginJob.indexOf("run: npm ci") < pluginJob.indexOf("run: tests/run_all.sh"),
  "the plugin job must install declared test dependencies before the canonical suite")
assert.equal(packageJson.scripts.test, "bash tests/run_all.sh", "npm test must delegate to the canonical runner")
assert.match(testing, /npm test/, "the contributor testing entry point must use the canonical runner")
assert.match(testing, /PRIVACY_RUNTIME_TESTS=always/, "testing guidance must describe the forced runtime-QML path")
assert.match(qmlLint, /\.\/\*\.qml[\s\S]*?\.\/tests\/qml\/\*\.qml[\s\S]*?sort/,
  "QML linting must discover production and runtime harnesses deterministically")
assert.match(ci, /QMLLINT=\/usr\/lib\/qt6\/bin\/qmllint[\s\S]*?scripts\/lint-qml/,
  "CI must use the same QML lint inventory as contributors")
assert.match(testing, /scripts\/lint-qml/, "testing guidance must advertise the shared QML lint entry point")
assert.match(live, /diagnostics summary/)
assert.match(live, /toggle __invalid__/)
assert.doesNotMatch(live, /\b(clearHistory|lockdown|refresh|rescan)\b/,
  "live IPC verification must remain read-only")
assert.equal(packageJson.scripts["verify:live"], "bash scripts/verify-live")

console.log("canonical test runner checks passed")
