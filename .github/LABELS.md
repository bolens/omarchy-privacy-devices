# Labels

Issue forms apply a change-type label and `needs-triage`. Pull requests are
labeled from changed paths and semantic branch prefixes by
[`.github/labeler.yml`](labeler.yml). Path-derived labels are synchronized when
the pull request changes; manually applied labels are preserved.

## Automatic labels

- `bug`, `enhancement`, and `documentation` describe the change type.
- `dependencies`, `docker`, and `github-actions` identify update tooling.
- `ci`, `tests`, `qml`, `javascript`, `shell`, `site`, and `metadata`
  identify affected implementation areas.
- `release` is applied to pull requests from a `release/` branch.
- `needs-triage` marks newly filed issues for initial review.

## Manual labels

Use `security` for security-sensitive work, `breaking-change` for incompatible
changes, and the standard lifecycle labels such as `duplicate`, `invalid`,
`help wanted`, and `wontfix` when triaging.

