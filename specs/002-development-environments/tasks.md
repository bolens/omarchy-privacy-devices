# Tasks

- [x] Add locked tools, pinned validator, and source-free image adapters.
- [x] Pass deterministic native and container validation.
- [ ] Verify archive exclusions and platform CI; record Apple execution limits.
- [ ] Complete protected merge and cleanup.

Native devenv and rootless Podman passed the JavaScript/helper suite and 79 Python tests, with live QML checks explicitly skipped. Fixture repairs preserve the /tmp audit boundary and resolve only required text utilities in the fake command directory. The pinned validator runs without installing Omarchy. Docker/macOS CI and Apple execution remain pending.
