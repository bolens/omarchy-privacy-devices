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

## Repository policy extension, specified 2026-11-07

Add credential-free, always-selected PR/main/manual repository policy using the
same pinned shared source/workflow policy, changelog validator and per-repository
HTML/XML/Lychee policy. Keep the accepted offline QML runtime separate. Every
validator failure must fail this workflow; Tidy warnings alone remain nonfatal.
Retained GitHub requirements and reusable release calls remain unchanged until
separate observed native PR/main evidence and Root's protected-check cutover.
