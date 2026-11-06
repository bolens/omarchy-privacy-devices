# Implementation plan

Own `.woodpecker/plugin.yml`, `scripts/woodpecker-plugin.sh`, archive exclusions
and CI/release documentation. Reuse the current GitHub plugin commands in the
existing immutable public toolchain, fetch the exact supported Omarchy commit
in an owned temporary directory and remove only that directory on exit.

Constitution checks: fixtures remain isolated; no live service/device/shell
control is added. No plugin runtime contract or persistent user data changes.
Root coordinator owns activation and protected-check settings.
