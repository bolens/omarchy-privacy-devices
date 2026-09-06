# Requirement coverage

| Requirement | Source and acceptance evidence |
| --- | --- |
| FR-001 | Model classification/health functions, PrivacyObserverController.qml, session and observer tests. |
| FR-002 | PrivacyControlTransactionController.qml, privacy-control, control/security tests, and transaction runtime harnesses. |
| FR-003 | Service operation tokens, PrivacyControlProcessController.qml, PrivacyObserverController.qml, static and runtime ownership tests. |
| FR-004 | privacy-settings, privacy-history, mutation/transfer controllers, Python filesystem and contention tests. |
| FR-005 | Model normalization, privacy-diagnostics, privacy-action, security and diagnostics tests. |
| FR-006 | privacy-control, privacy-recording, privacy-screenshot, SECURITY.md, and helper security tests. |

## Verification receipt

On 2026-09-05: With locked dependencies installed, the native suite passed JavaScript tests, 74 Python tests, shell checks, QML lint, and clean-archive validation. Runtime QML tests were explicitly skipped. Live controls and graphical runtime harnesses were not run. A separate self-review traced the listed source owners, mutation/observation boundaries, failure paths, and test assertions. No corrective runtime gap was established within this retrospective contract; real-engine and live operational evidence remain explicitly separate. Hosted delivery evidence belongs to the PR.
