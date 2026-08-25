#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");
const manifest = JSON.parse(read("manifest.json"));
const changelog = read("CHANGELOG.md");
const bugTemplate = read(".github/ISSUE_TEMPLATE/bug.yml");
const releaseWorkflow = read(".github/workflows/release.yml");

assert.match(
  manifest.version,
  /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/,
  "manifest version must be a stable SemVer release"
);

const escapedVersion = manifest.version.replace(/\./g, "\\.");
assert.match(
  changelog,
  new RegExp(`^## \\[${escapedVersion}\\] - \\d{4}-\\d{2}-\\d{2}$`, "m"),
  "changelog must contain a dated section for the manifest version"
);
assert.match(
  changelog,
  new RegExp(`^\\[Unreleased\\]: .+/compare/v${escapedVersion}\\.\\.\\.HEAD$`, "m"),
  "Unreleased must compare the manifest version with HEAD"
);
assert.match(
  changelog,
  new RegExp(`^\\[${escapedVersion}\\]: .+/compare/v\\d+\\.\\d+\\.\\d+\\.\\.\\.v${escapedVersion}$`, "m"),
  "current release link must compare the previous tag with the manifest version"
);
assert.match(
  bugTemplate,
  new RegExp(`placeholder: ["']?${escapedVersion}["']?`),
  "bug-report version example must match the manifest version"
);
assert.match(
  releaseWorkflow,
  /test "\$RELEASE_TAG" = "v\$\(jq -r \.version manifest\.json\)"/,
  "release workflow must reject tags that differ from the manifest version"
);

console.log(`release metadata checks passed for v${manifest.version}`);
