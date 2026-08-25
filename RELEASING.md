# Release playbook

This playbook covers release preparation, publication, verification, and
recovery. Releases follow Semantic Versioning and are published from an
annotated `vX.Y.Z` tag on `main`.

## 1. Choose the version

- Patch: compatible bug fixes only.
- Minor: backward-compatible features or meaningful new settings.
- Major: incompatible manifest, settings, storage, or behavior changes.

Confirm that `manifest.json` is the only authoritative runtime version. Update
issue-template examples when they display a concrete version.

## 2. Prepare the release commit

1. Update `manifest.json`.
2. Move completed entries from `Unreleased` into a dated changelog section.
3. Update changelog comparison links:
   - `Unreleased` compares the new tag to `HEAD`.
   - The new version compares the previous tag to the new tag.
4. Confirm user-visible behavior is reflected in `README.md` and the Pages
   guide. Update `ARCHITECTURE.md` or `TESTING.md` when their contracts change.
5. Run the validation matrix in [TESTING.md](TESTING.md).

Keep the release commit limited to version and documentation changes whenever
possible. Do not tag a dirty worktree or a commit that differs from the green
CI revision.

## 3. Validate the release candidate

Push the release-preparation commit through the normal review path and require
both CI jobs to pass:

- `Plugin`: manifest validation, QML lint, helper checks, and behavior tests.
- `Repository`: issue forms, documentation, links, site behavior, and
  accessibility.

Record the candidate SHA:

```sh
release_sha=$(git rev-parse HEAD)
git status --short
gh run list --commit "$release_sha"
```

The status output must be empty. If CI fails, fix the cause in a new commit,
rerun the full matrix, and use the new SHA as the candidate.

## 4. Tag and publish

Create an annotated tag only after `origin/main` and the candidate SHA match:

```sh
version=$(jq -r .version manifest.json)
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"
git tag -a "v$version" -m "Privacy Devices $version"
git push origin "v$version"
```

The Release workflow rejects a tag that does not match the manifest version.
It reruns validation, builds `privacy-devices-X.Y.Z.tar.gz`, creates a SHA-256
checksum, and publishes both files with GitHub-generated release notes.

## 5. Verify publication

```sh
version=$(jq -r .version manifest.json)
run_id=$(gh run list --workflow Release --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch --exit-status "$run_id"
gh release view "v$version"
```

Verify all of the following:

- The release tag targets the validated commit.
- The archive and checksum are attached.
- The checksum validates after downloading the archive.
- The Pages site displays the new version.
- A clean Omarchy installation can install or update the plugin.
- The official plugin directory reflects the release.

### Marketplace update readiness

The community directory follows the repository's default-branch head during
scheduled catalog refreshes. Before requesting verification of a newer
upstream snapshot, confirm that the public repository has the release commit,
root `manifest.json`, `README.md`, `LICENSE`, and `preview.png`; that the plugin
ID is unchanged; and that install, update, and removal instructions remain
accurate. Use the marketplace's existing-listing verification flow rather than
opening a duplicate submission. Treat marketplace validation as compatibility
and baseline review, not as a security certification.

## 6. Recovery

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
