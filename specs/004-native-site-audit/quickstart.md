# Quickstart

Build with `npm ci`, `npm run build:site`, and `npm run test:site` in the documented toolchain. Inside the pinned official browser image, run `node scripts/audit-site.mjs`. The helper reads `_site` and writes diagnostics to stdout/stderr. Ordinary host execution requires the same image-provided Puppeteer and Chrome; it must not silently discover an unrelated installed browser.
