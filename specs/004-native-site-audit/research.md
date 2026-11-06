# Research

- Repeated hosted ChromeLauncher startup ECONNREFUSED occurred before navigation on Privacy and MMW. Empty Chrome stderr and a live Chrome process do not establish application failure. Avoid more unchanged retries.
- [Official Puppeteer image](https://pptr.dev/guides/docker) bundles Chrome for Testing and dependencies.25.16.0 manifest SHA256 is `956a72e3d523c76606efaad23392fbe33950370189f749715222c7427f57392b`; config reports Node24.21.0 and UID10042. Its documented sandbox default requires SYS_ADMIN; this proposal explicitly uses isolated headless no-sandbox without adding capabilities.
- Puppeteer launch resolves after browser readiness. An owned HTTP server listens on port0 and reports its actual assigned address. Lighthouse connects to the already-ready DevTools endpoint rather than discovering a host browser.
- The shared App Drawer unprivileged runtime canary017a passed: Node24.21.0, bundled Chrome156.0.8078.47, accessibility score1, read-only browser root, no capabilities, no network, and successful owned-resource cleanup. This target site still requires its own native final-head PR and genuine-main evidence.
