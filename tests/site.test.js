#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { JSDOM } = require("jsdom");

const root = path.resolve(__dirname, "..");
const html = fs.readFileSync(path.join(root, "docs/index.html"), "utf8");

function pngDimensions(relativePath) {
  const image = fs.readFileSync(path.join(root, relativePath));
  assert.deepEqual([...image.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
  return [image.readUInt32BE(16), image.readUInt32BE(20)];
}

assert.match(html, /<main id="main">/);
assert.match(html, /@media \(prefers-reduced-motion: reduce\)/);
assert.match(html, /property="og:site_name"/);
assert.match(html, /name="twitter:title"/);
assert.equal((html.match(/data-copy=/g) || []).length, 4);
const panelCaptureWidth = 532;
assert.deepEqual(pngDimensions("preview.png"), [panelCaptureWidth, 500]);
assert.deepEqual(pngDimensions("docs/preview.png"), [panelCaptureWidth, 500]);
assert.deepEqual(pngDimensions("docs/appearance.png"), [panelCaptureWidth, 660]);
for (const page of ["general", "alerts", "monitoring", "device", "history"])
  assert.deepEqual(pngDimensions(`docs/${page}.png`), [panelCaptureWidth, 660]);
assert.deepEqual(pngDimensions("docs/monitoring-private.png"), [panelCaptureWidth, 330]);
assert.deepEqual(pngDimensions("docs/monitoring-health.png"), [panelCaptureWidth, 290]);
assert.deepEqual(pngDimensions("docs/history-disabled.png"), [panelCaptureWidth, 240],
  "the disabled history state should be cropped to its compact content");
const notificationDimensions = pngDimensions("docs/notification.png");
assert.ok(notificationDimensions[0] >= 360 && notificationDimensions[0] <= 600,
  "notification capture must remain readable without excess desktop area");
assert.ok(notificationDimensions[1] >= 80 && notificationDimensions[1] <= 240,
  "notification capture must remain tightly cropped around the toast");
const barDimensions = pngDimensions("docs/bar.png");
assert.equal(barDimensions[1], 50, "bar capture must retain the live horizontal-bar height");
assert.ok(barDimensions[0] > 0 && barDimensions[0] <= 500, "bar capture must be a tightly bounded live widget footprint");
assert.equal(new Set(
  ["general", "appearance", "alerts", "monitoring", "monitoring-private", "monitoring-health", "device", "history", "history-disabled"]
    .map((page) => fs.readFileSync(path.join(root, `docs/${page}.png`)).toString("base64"))
).size, 9, "each settings and detail state must have a distinct capture");
assert.equal(
  Buffer.compare(fs.readFileSync(path.join(root, "preview.png")), fs.readFileSync(path.join(root, "docs/preview.png"))),
  0
);
assert.match(html, /src="appearance\.png"[^>]+width="532" height="660"/);
for (const image of ["bar", "notification", "general", "appearance", "alerts", "monitoring", "monitoring-private", "monitoring-health", "device", "history", "history-disabled"]) {
  assert.match(html, new RegExp(`src="${image}\\.png"`));
  assert.match(fs.readFileSync(path.join(root, "README.md"), "utf8"), new RegExp(`docs/${image}\\.png`));
}

const source = new JSDOM(html).window.document;
assert.ok(source.querySelector('nav a[href="#screenshots"]'),
  "primary navigation must expose the interface gallery");
assert.ok(html.indexOf('id="screenshots"') < html.indexOf('id="install"') &&
  html.indexOf('id="install"') < html.indexOf('id="requirements"'),
  "installation must follow visual proof before detailed compatibility guidance");
assert.match(html, /\.site-header\s*\{[^}]*position:\s*sticky/s,
  "primary navigation must remain visible through the long guide");
assert.match(html, /@media \(max-width: 760px\)[\s\S]*?\.site-header\s*\{\s*position:\s*static;/,
  "mobile navigation must not consume the viewport while scrolling");
assert.equal(source.querySelectorAll("#screenshots .interface-showcase .screenshot-card").length, 3,
  "activity, bar, and notification captures must form the interface showcase");
assert.equal(source.querySelectorAll("#screenshots [data-gallery]").length, 2,
  "settings and workflow captures must be split into focused explorers");
assert.equal(source.querySelectorAll("#screenshots [data-gallery] .gallery-panel").length, 9,
  "every settings and detail capture must remain available in a tab panel");
assert.match(html, /\.gallery-explorer\s*\{[^}]*grid-template-columns:\s*14rem minmax\(0, 1fr\)/s,
  "wide screens must pair gallery navigation with one focused image stage");
assert.match(html, /\.js \.gallery-stage \.gallery-panel\[hidden\]\s*\{\s*display:\s*none;/,
  "enhanced galleries must render only the selected image panel");
assert.doesNotMatch(html, /measured widget footprint|width varies/i,
  "gallery captions must explain visible status instead of capture mechanics");
assert.doesNotMatch(html, /official Omarchy (?:Shell )?plugin|official Omarchy Plugins directory/i,
  "the independent community marketplace must not be described as official");
assert.match(html, /detected application icon/i,
  "notification guidance must explain app-aware icons");
for (const image of ["preview", "bar", "notification", "general", "appearance", "alerts", "monitoring", "monitoring-private", "monitoring-health", "device", "history", "history-disabled"]) {
  const element = source.querySelector(`#screenshots img[src="${image}.png"]`);
  assert.ok(element, `Pages gallery must showcase ${image}.png`);
  assert.deepEqual(
    [Number(element.getAttribute("width")), Number(element.getAttribute("height"))],
    pngDimensions(`docs/${image}.png`),
    `Pages dimensions must match ${image}.png`
  );
}

let copied = "";
const dom = new JSDOM(html, {
  runScripts: "dangerously",
  url: "https://example.test/?theme=gruvbox",
  beforeParse(window) {
    window.fetch = async () => ({
      ok: true,
      json: async () => ({ version: "9.8.7" })
    });
    Object.defineProperty(window.navigator, "clipboard", {
      value: { writeText: async (value) => { copied = value; } }
    });
  }
});

const settle = () => new Promise((resolve) => setTimeout(resolve, 25));

(async () => {
  await settle();
  const { document } = dom.window;

  assert.equal(document.documentElement.dataset.theme, "gruvbox");
  assert.match(document.querySelector('link[rel="icon"]').href, /^data:image\/svg\+xml/);
  assert.equal(document.querySelector("#plugin-version").textContent, "v9.8.7");

  const settingsGallery = document.querySelector('[data-gallery]');
  const settingsTabs = settingsGallery.querySelectorAll('[role="tab"]');
  const settingsPanels = settingsGallery.querySelectorAll('[role="tabpanel"]');
  assert.equal([...settingsPanels].filter((panel) => !panel.hidden).length, 1);
  settingsTabs[1].click();
  assert.equal(settingsTabs[1].getAttribute("aria-selected"), "true");
  assert.equal([...settingsPanels].find((panel) => !panel.hidden).id, settingsTabs[1].dataset.target);
  settingsTabs[1].dispatchEvent(new dom.window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }));
  assert.equal(settingsTabs[2].getAttribute("aria-selected"), "true");

  document.querySelector("[data-copy]").click();
  await settle();
  assert.match(copied, /^omarchy plugin add /);
  assert.equal(document.querySelector("[data-copy]").textContent, "Copied!");

  dom.window.close();
  console.log("site behavior checks passed");
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
