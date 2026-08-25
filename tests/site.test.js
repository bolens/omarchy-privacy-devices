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
assert.deepEqual(pngDimensions("preview.png"), [500, 500]);
assert.deepEqual(pngDimensions("docs/preview.png"), [500, 500]);
assert.deepEqual(pngDimensions("docs/appearance.png"), [500, 660]);
for (const page of ["general", "alerts", "monitoring", "device"])
  assert.deepEqual(pngDimensions(`docs/${page}.png`), [500, 660]);
const barDimensions = pngDimensions("docs/bar.png");
assert.equal(barDimensions[1], 50, "bar capture must retain the live horizontal-bar height");
assert.ok(barDimensions[0] > 0 && barDimensions[0] <= 500, "bar capture must be a tightly bounded live widget footprint");
assert.equal(new Set(
  ["general", "appearance", "alerts", "monitoring", "device"]
    .map((page) => fs.readFileSync(path.join(root, `docs/${page}.png`)).toString("base64"))
).size, 5, "each settings page must have a distinct capture");
assert.equal(
  Buffer.compare(fs.readFileSync(path.join(root, "preview.png")), fs.readFileSync(path.join(root, "docs/preview.png"))),
  0
);
assert.match(html, /src="appearance\.png"[^>]+width="500" height="660"/);
for (const image of ["bar", "general", "appearance", "alerts", "monitoring", "device"]) {
  assert.match(html, new RegExp(`src="${image}\\.png"`));
  assert.match(fs.readFileSync(path.join(root, "README.md"), "utf8"), new RegExp(`docs/${image}\\.png`));
}

const source = new JSDOM(html).window.document;
for (const image of ["preview", "bar", "general", "appearance", "alerts", "monitoring", "device"]) {
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
