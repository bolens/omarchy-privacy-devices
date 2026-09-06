# Tasks

- [x] Add locked tools, pinned validator, and source-free image adapters.
- [x] Pass deterministic native and container validation.
- [x] Verify native Linux/macOS and Linux Docker checks on the recorded main revision.
- [x] Verify merged source delivery and the applicable main-revision workflows.

Historical pre-merge observation (superseded by the receipt below):
Native devenv and rootless Podman passed the JavaScript/helper suite and 79 Python tests, with live QML checks explicitly skipped. Fixture repairs preserve the /tmp audit boundary and resolve only required text utilities in the fake command directory. The pinned validator runs without installing Omarchy. Docker/macOS CI and Apple execution remain pending.

## Delivery verification — 2026-09-06

The [development workflow](https://github.com/bolens/omarchy-privacy-devices/actions/runs/34030559711) passed on
`b44a64aebd7d39e041ba17433e3bfa37a061f630`. Both native platform jobs ran successfully;
the Linux job also executed and passed the Docker development-image check. All
applicable workflows observed for that main revision completed successfully.

Actual Apple container-engine execution remains unverified. Native macOS devenv
validation does not establish that engine's runtime behavior. Existing live-host
and optional dependency limits still apply. Checkout cleanup remains part of each
task's delivery procedure and is not inferred from CI success.
