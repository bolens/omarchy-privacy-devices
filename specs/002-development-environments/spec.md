# Development environments

Provide a locked devenv shell and source-free Linux development image for the privacy plugin deterministic suite, using the pinned Omarchy validator and locked npm dependencies. Support local Docker, Podman, and Apple container adapters without connecting host devices, PipeWire, the compositor, or privileged helpers.

Acceptance: native development and container tests preserve argument and file-ownership boundaries, run JavaScript/Python/helper checks, and validate a clean plugin archive. Development files stay out of release archives. QML and real-device observations remain separately reported host checks.
