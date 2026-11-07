# Validation guide

Use the supported immutable imports and reviewed toolchain in an owned checkout.
Run the repository's normal language/contract gate first:

```sh
PRIVACY_RUNTIME_TESTS=never npm test
```

Follow [TESTING.md](../../TESTING.md) for the existing QML inventory and explicit
isolated engine cases. Portable or forced-runtime skips do not prove engine behavior.

After integration, verify a valid component passes and deliberately missing member,
type and nested token controls fail through the same real strict gate. Verify readonly
token replacement fails while the existing mutable child remains writable.

Runtime acceptance must use fixture-only commands and owned HOME/XDG/Quickshell roots,
compare older/current palette behavior and all original/named token fields, and recheck
public readiness after the current event completes. Do not run a live desktop verifier,
install/reload a plugin, or manipulate devices/services as part of this procedure.

Record exact source/image identities and actual final-head plus genuine-main results.
An unknown vendor hash, setup failure or source mismatch stops acceptance. See
[plan.md](plan.md) for implementation boundaries and tasks for current evidence.
