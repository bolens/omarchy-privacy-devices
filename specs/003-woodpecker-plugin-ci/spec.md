# Woodpecker plugin validation

Requested migration, specified before implementation delivery.

- Run the existing non-graphical plugin gate for exact PR and main revisions.
- Preserve immutable toolchain/import pins, archive and shell checks, model
  behavior tests and mandatory QML lint. Fail on any check failure.
- Use ordinary disposable Docker backend containers, no host mounts, socket,
  privileges or secrets. Live desktop behavior remains a separate host check.
- Keep GitHub repository/security/browser/platform/release checks until their
  equivalent migration and protected-check cutover are separately verified.
- Prove an actual native PR and genuine main run before calling delivery done.
