const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const sourceRoot = path.join(__dirname, "..")
const gitEnvironment = { ...process.env }
for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_PREFIX"]) delete gitEnvironment[name]
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-site-build-"))
try {
  fs.mkdirSync(path.join(temporary, "scripts"))
  fs.mkdirSync(path.join(temporary, "docs"))
  fs.copyFileSync(path.join(sourceRoot, "scripts", "build-site.sh"), path.join(temporary, "scripts", "build-site.sh"))
  fs.chmodSync(path.join(temporary, "scripts", "build-site.sh"), 0o755)
  fs.writeFileSync(path.join(temporary, "manifest.json"), '{"version":"1.2.3"}\n')
  fs.writeFileSync(path.join(temporary, "docs", "index.html"), "<p>__PLUGIN_VERSION__</p>\n")
  fs.writeFileSync(path.join(temporary, "docs", "sitemap.xml"), "<url><loc>test</loc></url>\n")
  fs.writeFileSync(path.join(temporary, "docs", "asset.txt"), "current\n")
  fs.mkdirSync(path.join(temporary, "_site"))
  fs.writeFileSync(path.join(temporary, "_site", "stale.txt"), "stale\n")
  for (const arguments of [["init", "-q"], ["config", "user.email", "test@example.test"], ["config", "user.name", "Test"], ["add", "."], ["commit", "-qm", "fixture"]]) {
    const git = spawnSync("git", arguments, { cwd: temporary, encoding: "utf8", env: gitEnvironment })
    assert.equal(git.status, 0, git.error?.message ?? git.stderr ?? "git exited without diagnostics")
  }

  const result = spawnSync(path.join(temporary, "scripts", "build-site.sh"), [], { cwd: "/", encoding: "utf8" })
  assert.equal(result.status, 0, result.stderr)
  assert.equal(fs.existsSync(path.join(temporary, "_site", "stale.txt")), false)
  assert.equal(fs.readFileSync(path.join(temporary, "_site", "manifest.json"), "utf8"), '{"version":"1.2.3"}\n')
  assert.match(fs.readFileSync(path.join(temporary, "_site", "index.html"), "utf8"), /1\.2\.3/)
  assert.match(fs.readFileSync(path.join(temporary, "_site", "sitemap.xml"), "utf8"), /<lastmod>\d{4}-\d{2}-\d{2}<\/lastmod>/)
} finally {
  fs.rmSync(temporary, { recursive: true, force: true })
}

console.log("site build tests passed")
