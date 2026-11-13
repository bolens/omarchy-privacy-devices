#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const root = path.resolve(__dirname, "..");
const rootGuides = [
  "README.md",
  "ARCHITECTURE.md",
  "CHANGELOG.md",
  "CODE_OF_CONDUCT.md",
  "CONTRIBUTING.md",
  "RELEASING.md",
  "SECURITY.md",
  "SUPPORT.md",
  "TESTING.md"
];
const index = fs.readFileSync(path.join(root, "DOCUMENTATION.md"), "utf8");

for (const guide of rootGuides) {
  assert.match(index, new RegExp(`\\(${guide.replace(/\./g, "\\.")}\\)`), `${guide} must be listed in DOCUMENTATION.md`);
  const content = fs.readFileSync(path.join(root, guide), "utf8");
  assert.match(content, /\(DOCUMENTATION\.md\)/, `${guide} must link back to the documentation index`);
}

function collect(directory, repositoryRoot = directory, files = []) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if ([".git", "node_modules", "_site"].includes(entry.name)) continue;
    if (directory === repositoryRoot && entry.name === ".woodpecker-qml-input") continue;
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) collect(absolute, repositoryRoot, files);
    else if (entry.name.endsWith(".md")) files.push(absolute);
  }
  return files;
}

// Ignore only the prepared supplier at the checkout root. Maintained nested
// directories, including one with the same basename, retain their link checks.
const fixture = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-doc-scope-"));
try {
  for (const relative of ["README.md", "docs/guide.md", "docs/.woodpecker-qml-input/owned.md", ".woodpecker-qml-input/omarchy/AGENTS.md"]) {
    const absolute = path.join(fixture, relative);
    fs.mkdirSync(path.dirname(absolute), { recursive: true });
    fs.writeFileSync(absolute, "[fixture](missing.md)\n");
  }
  assert.deepEqual(collect(fixture).map(file => path.relative(fixture, file)).sort(),
    ["README.md", "docs/.woodpecker-qml-input/owned.md", "docs/guide.md"]);
} finally {
  fs.rmSync(fixture, { recursive: true, force: true });
}

const markdownFiles = collect(root);

for (const file of markdownFiles) {
  const content = fs.readFileSync(file, "utf8");
  for (const match of content.matchAll(/!?\[[^\]]*\]\(([^)]+)\)/g)) {
    const target = match[1].trim().replace(/^<|>$/g, "").split(/[?#]/, 1)[0];
    if (!target || /^(?:[a-z]+:|\/)/i.test(target)) continue;
    const resolved = path.resolve(path.dirname(file), decodeURIComponent(target));
    assert.ok(resolved.startsWith(root + path.sep), `${path.relative(root, file)} link escapes the repository: ${target}`);
    assert.ok(fs.existsSync(resolved), `${path.relative(root, file)} has missing local link: ${target}`);
  }
}

const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");
assert.match(readme, /!\[Privacy Devices activity panel[^\]]*\]\(preview\.png\?v=[0-9a-f]{12}\)/,
  "README must show a content-addressed current primary preview");
const readmeImages = [...readme.matchAll(/(?:!\[[^\]]*\]\(|<img\s+[^>]*?src=")((?:docs\/)?[A-Za-z0-9_-]+\.png)\?v=([0-9a-f]{12})/g)];
assert.ok(readmeImages.length >= 12, "README screenshot references must be content-addressed");
for (const [, image, token] of readmeImages) {
  const digest = require("node:crypto").createHash("sha256").update(fs.readFileSync(path.join(root, image))).digest("hex").slice(0, 12);
  assert.equal(token, digest, `README cache token must match ${image}`);
}
assert.match(readme, /docs\/device\.png/, "README must show the individual device settings page");
assert.match(readme, /docs\/notification\.png/, "README must show the app-aware notification example");
assert.match(readme, /docs\/monitoring-private\.png/, "README must show private history and transfer settings");
assert.match(readme, /docs\/monitoring-health\.png/, "README must show observer health settings");
for (const capability of ["privacy lockdown", "device-aware visibility", "today\/seven-day summaries"])
  assert.match(readme, new RegExp(capability, "i"), `README must summarize ${capability}`);

console.log("documentation structure checks passed");
