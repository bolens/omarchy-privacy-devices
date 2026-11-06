# Audit command contract

`node scripts/audit-site.mjs` reads the repository `_site` directory and locked Lighthouse package, plus image-owned Puppeteer/Chrome. Success requires an actual accessibility report with score exactly1. Failure, signal, malformed result, missing input, and startup timeout return nonzero. Never expose a public listening socket; bind loopback and allocate ephemeral ports. Report paths and temporary browser profiles belong to the current invocation only. No publishing credentials or host capabilities are inputs.
