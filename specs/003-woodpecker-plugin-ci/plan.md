# Implementation plan

Own `.woodpecker/plugin.yml`, `scripts/woodpecker-plugin.sh`, archive exclusions
and CI/release documentation. Reuse the current GitHub plugin commands in the
existing immutable public toolchain, fetch the exact supported Omarchy commit
in an owned temporary directory and remove only that directory on exit.

Constitution checks: fixtures remain isolated; no live service/device/shell
control is added. No plugin runtime contract or persistent user data changes.
Root coordinator owns activation and protected-check settings.

## Additive repository policy plan

Own `.woodpecker/repository.yml`, `scripts/woodpecker-repository.sh`, the document
validator and focused failure controls. Use disposable public tooling containers
without credentials, host mounts, Docker sockets or additional privileges. Fetch
the exact existing shared source policy, verify downloaded executable checksums,
preserve each repository's link exceptions, and keep the real site accessibility
audit in its existing workflow. Preserve all normal hooks and release callers.
