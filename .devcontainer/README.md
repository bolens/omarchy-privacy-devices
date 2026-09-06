# omarchy-privacy-devices devcontainer

Open this repository in VS Code and run **Dev Containers: Reopen in
Container**. A local Docker-compatible engine and the Dev Containers extension
are required. The first build downloads the pinned tool images and distribution
packages. Setup installs dependencies from this checkout's lockfiles and runs
`smoke.sh`. Rebuild the container after Dockerfile changes. Rerun
`bash .devcontainer/post-create.sh` after changing dependency lockfiles.

Includes Node, Python, Ruby, ShellCheck and Qt QML test tools. Portable model
and contract tests run without a desktop. Full QML integration needs the
documented Omarchy/Quickshell imports and an isolated graphical session. No
host session sockets, devices or settings are mounted.

Run from the workspace root:

```sh
(
  set -e
  for test_file in tests/*.test.js; do node "$test_file"; done
  python3 -m unittest discover -s tests -p 'test_*.py'
)
```

The editor runs as `vscode`, with its UID adjusted for the local workspace. The
source is bind-mounted at `/workspace` and is never copied into image layers.
Use a regular clone when the container cannot see a linked worktree's external
Git directory. Keep credentials in your local development environment.

`bash .devcontainer/smoke.sh` checks installed tools and checkout access. It
does not run the application test suite. No application starts automatically.
Image references include immutable digests. Dependabot monitors the Dockerfiles
where supported. Distribution packages resolve from the configured Debian
repositories at build time. Update image pins and rerun setup and native checks
together. Existing native and Nix workflows remain available independently.
