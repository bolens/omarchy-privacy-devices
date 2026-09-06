# VS Code for omarchy-privacy-devices

Open this repository as a folder, or add it as a folder in a multi-root workspace.
Install the recommendations from the Extensions view. Use **Tasks: Run Task** for
the commands below. Tasks run from this repository unless they state another directory.

Use the tool versions documented by the repository. Launch VS Code from the
prepared development shell, or reopen in the existing dev container when available.
Extension recommendations do not install command-line dependencies.

| Task | Command |
| --- | --- |
| npm test | `npm test` |
| npm build:site | `npm run build:site` |
| npm test:site | `npm run test:site` |
| Lint QML | `bash scripts/lint-qml` |
| Check diff whitespace | `git diff --check` |

This checkout has no application debug entry configured. Use its validation tasks
and the editor support for its source and configuration files.
