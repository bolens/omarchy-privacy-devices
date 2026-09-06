# Implementation plan

Own devenv inputs and lock, container helper and regression tests, environment CI, ignored state, archive exclusions, and contributor documentation. Pin the same Omarchy validator revision used by existing CI as a non-flake source input. Install npm dependencies with the committed lockfile and disabled install scripts before running the canonical test suite.

Set the existing runtime-test mode to never in the development environment. Tests use fixtures and temporary state. Preserve runtime metadata, device-control code, settings, and release version. Validate native devenv and actual Podman before pushing; require applicable current-head CI before protected merge. No plugin release is needed for development tooling alone.
