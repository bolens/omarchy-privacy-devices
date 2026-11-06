# Release playbook

Releases use Semantic Versioning and annotated `vX.Y.Z` tags on `main`.

## 1. Choose the version

- Patch: compatible bug fixes only.
- Minor: backward-compatible features or meaningful new settings.
- Major: incompatible manifest, settings, storage, or behavior changes.

Confirm that `manifest.json` is the only authoritative runtime version. Update
issue-template examples when they display a concrete version.

## 2. Prepare the release commit

Start from the current remote default branch and prepare releases on a dedicated
branch. Direct pushes to `main` are blocked, including for administrators.

```sh
git fetch origin
git switch main
git pull --ff-only origin main
version=X.Y.Z
git switch -c "release/v$version"
```

1. Update `manifest.json`.
2. Move completed entries from `Unreleased` into a dated changelog section.
3. Update changelog comparison links:
   - `Unreleased` compares the new tag to `HEAD`.
   - The new version compares the previous tag to the new tag.
4. Confirm user-visible behavior is reflected in `README.md` and the Pages
   guide. Update `ARCHITECTURE.md` or `TESTING.md` when their contracts change.
5. Run the validation matrix in [TESTING.md](TESTING.md).

Keep release commits limited to version and documentation when possible. Push
the release branch, not `main`.

## 3. Open and validate the release pull request

Push the branch and open a pull request against `main`:

```sh
git push -u origin HEAD
gh pr create --base main --head "release/v$version" \
  --title "Release $version" --fill
pr=$(gh pr view --json number --jq .number)
gh pr checks "$pr" --watch --fail-fast
```

Branch protection requires the pull request path, a linear history, resolved
conversations, and both strict CI checks:

- `Plugin`: manifest validation, QML lint, helper checks, and behavior tests.
- `Repository`: issue forms, documentation, links, site behavior, and
  accessibility.

Only squash merges are enabled. After all checks pass and conversations are
resolved, squash-merge onto protected `main` and delete the release branch:

```sh
gh pr merge "$pr" --squash --delete-branch
```

If CI fails, fix forward on the same release branch and rerun the full matrix.
Do not bypass protection or push the release commits directly to `main`.

## 4. Validate the merged candidate

The squash merge creates one reviewed commit on protected `main`. Fetch the
resulting release candidate, confirm the pull request's final commit is at
the tip of `main`, fast-forward the clean local
branch, and wait for the push-triggered CI runs on that exact commit:

```sh
git fetch origin main
release_sha=$(git rev-parse origin/main)
merged_sha=$(gh pr view "$pr" --json mergeCommit --jq .mergeCommit.oid)
test "$release_sha" = "$merged_sha"
git switch main
git merge --ff-only origin/main
run_id=""
for _attempt in {1..24}; do
  run_id=$(gh run list --workflow CI --commit "$release_sha" --limit 1 \
    --json databaseId --jq '.[0].databaseId // empty')
  [[ -n $run_id ]] && break
  sleep 5
done
test -n "$run_id"
gh run watch --exit-status "$run_id"
```

Both `Plugin` and `Repository` must pass on the merged candidate. The local
worktree must also be clean. If post-merge CI fails, fix forward through a new
pull request and use its merged SHA as the new candidate.

## 5. Tag and publish

Create an annotated tag on the validated remote candidate. Do not tag a
release-branch commit, whose SHA is replaced by the squash merge:

```sh
version=$(git show "$release_sha:manifest.json" | jq -r .version)
test "$release_sha" = "$(git rev-parse origin/main)"
git tag -s "v$version" "$release_sha" -m "Privacy Devices $version"
git push origin "v$version"
```

The Release workflow rejects a tag that does not match the manifest version.
It reruns validation, builds `privacy-devices-X.Y.Z.tar.gz`, creates a SHA-256
checksum, attests the archive, and publishes both files with GitHub-generated
release notes.

## 6. Verify publication

```sh
version=$(jq -r .version manifest.json)
run_id=$(gh run list --workflow Release --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch --exit-status "$run_id"
gh release view "v$version"
gh attestation verify "privacy-devices-$version.tar.gz" \
  --repo bolens/omarchy-privacy-devices
```

Verify all of the following:

- The release tag targets the validated commit.
- The archive and checksum are attached.
- The checksum validates after downloading the archive.
- The artifact attestation verifies against this repository.
- The Pages site displays the new version.
- A clean Omarchy installation can install or update the plugin.
- The official plugin directory reflects the release.

### Marketplace update readiness

Before requesting marketplace verification, confirm the public release includes
`manifest.json`, `README.md`, `LICENSE`, and `preview.png`; the plugin ID and
lifecycle instructions remain correct. Update the existing listing rather than
submitting a duplicate.

## 7. Recovery

Never move or overwrite a published tag.

- Failed workflow before publication: fix forward, delete the unpublished
  local/remote tag if necessary, then tag the corrected commit.
- Broken published release: document impact, revert or fix on `main`, and ship
  a new patch release.
- Incorrect release notes or missing asset: edit the GitHub release or rerun
  asset publication without changing the tag target.
- Compromised artifact or unsafe behavior: mark the release as withdrawn,
  publish a security advisory when appropriate, and issue a patched version.

After recovery, verify installation, Pages, checksums, and the plugin directory
again.

## Related documentation

See the [documentation index](DOCUMENTATION.md), [changelog](CHANGELOG.md),
[testing guide](TESTING.md), and release [security checklist](SECURITY.md#release-security-checklist).

Fleet policy: <https://github.com/bolens/.github/blob/main/RELEASING.md>.

## Source lint

The Source lint workflow checks maintained python, javascript files selected by
[`.github/source-lint.json`](.github/source-lint.json) on every pull request
and push to `main`. Existing native checks remain part of the merge gate.
Use the [shared local reproduction instructions](https://github.com/bolens/.github/blob/7603518f305fb76f7bb1b9979f2692521f633b82/docs/source-lint.md)
with the same tooling revision pinned in
[the workflow](.github/workflows/source-lint.yml). Review exclusions when adding
source files; generated and imported files retain their native validation.
Require the new check to pass on the current PR head before merging.

## Woodpecker plugin validation

[Woodpecker](https://woodpecker.bolens.dev/repos) runs the plugin archive,
ShellCheck, behavior and QML lint checks on pull requests and pushes to `main`.
It uses the same immutable Omarchy toolchain image and v4.0.1 imports as
GitHub CI. The entry point is `bash scripts/woodpecker-plugin.sh` inside that
image. It requires network access only to fetch the pinned public imports
and any lockfile-based test dependencies; it receives no publishing secrets.

Require `ci/woodpecker/pr/plugin` for ordinary pull requests, alongside the
existing Repository, source-lint, and development-environment checks. GitHub
retains full plugin validation for reusable callers by default through the typed
`release_validation` input; the signed-release workflow explicitly enables it.
Ordinary PR and main workflows skip the duplicate hosted plugin jobs.

Repository links, HTML/XML, browser accessibility, workflow security, compatibility
canaries, macOS, development-image builds, Pages, and signed release publication
retain their existing GitHub workflows. Native plugin success does not prove live
desktop behavior. No version or release is created by CI.

## Woodpecker site accessibility

The native `site` workflow builds the existing Pages payload, runs its structure
tests, then runs `node scripts/audit-site.mjs` in the pinned official
Puppeteer/Chrome image. It requires an accessibility score exactly 1. The helper
awaits its own loopback HTTP listener and Chrome DevTools readiness, uses ephemeral
ports, and closes only its owned browser, profile, and server. It receives no
secrets or extra host capabilities.

The hosted browser check remains required during adoption. A source review or
local build does not establish runner success: verify the final-head native site
pipeline and genuine merged-main run before retiring hosted coverage or changing
its required checks. Publishing, signed releases, and platform checks keep their
current workflows. Review the manual browser-image digest pin alongside the
other native image pins; Dependabot does not update Woodpecker YAML.
