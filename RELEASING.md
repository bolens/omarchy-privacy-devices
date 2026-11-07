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

Branch protection requires the pull request path, linear history, resolved
conversations and all five contexts listed under [Required merge checks](#required-merge-checks).
The retained hosted `Plugin` job is release validation; ordinary pull requests
use the required native plugin and site contexts alongside the three hosted checks.

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
repo=bolens/omarchy-privacy-devices
run_id=$(gh run list --repo "$repo" --workflow CI --commit "$release_sha" \
  --event push --limit 1 --json databaseId --jq '.[0].databaseId // empty')
test -n "$run_id"
gh run watch "$run_id" --repo "$repo" --exit-status
```

Require the exact merged-commit hosted and native results described under
[Observe the exact merged candidate](#observe-the-exact-merged-candidate).
The local worktree must also be clean. If post-merge CI fails, fix forward through a new
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

Select the Release run for this exact tag and validated commit; verify its
reported `headSha`, `headBranch` and push event before accepting publication.

```sh
version=$(jq -r .version manifest.json)
run_id=$(gh run list --repo "$repo" --workflow Release --commit "$release_sha" \
  --event push --branch "v$version" --limit 1 --json databaseId --jq '.[0].databaseId // empty')
test -n "$run_id"
gh run view "$run_id" --repo "$repo" --json headSha,headBranch,event
gh run watch "$run_id" --repo "$repo" --exit-status
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

## Required merge checks

Protected `main` requires an up-to-date pull request, resolved conversations and
these five check contexts on the reviewed candidate:

- `Repository` (GitHub Actions app 15368).
- `lint / Source lint` (GitHub Actions app 15368).
- `Development environment` (GitHub Actions app 15368).
- `ci/woodpecker/pr/plugin`.
- `ci/woodpecker/pr/site`.

Require every context before an ordinary squash merge; missing, pending or failed
checks do not authorize a bypass. Woodpecker plugin and site results cover their
native suites separately. They do not replace retained GitHub repository, source
lint, development-environment, platform or signed-release validation, and none of
these CI results establishes physical desktop behavior.

## Observe the exact merged candidate

After the squash merge, record its `mergeCommit.oid`, fetch `main` and require
that commit to match the release candidate. Fast-forward only a clean local main
checkout. Query runs by the exact commit and push event, select the applicable
run ID, then let `gh run watch` observe its terminal state:

```sh
repo=bolens/omarchy-privacy-devices
release_sha=$(gh pr view "$pr" --repo "$repo" --json mergeCommit --jq .mergeCommit.oid)
git fetch origin main
test "$release_sha" = "$(git rev-parse origin/main)"
gh run list --repo "$repo" --commit "$release_sha" --event push \
  --json databaseId,workflowName,headSha,status,conclusion
run_id=$(gh run list --repo "$repo" --workflow CI --commit "$release_sha" \
  --event push --limit 1 --json databaseId --jq '.[0].databaseId // empty')
test -n "$run_id"
gh run watch "$run_id" --repo "$repo" --exit-status
gh api "repos/$repo/commits/$release_sha/check-runs?per_page=100" \
  --jq '.check_runs[] | {name,head_sha,status,conclusion,app_id:.app.id}'
gh api "repos/$repo/commits/$release_sha/status" \
  --jq '.statuses[] | {context,state,target_url}'
```

An absent run or status is pending evidence; inspect the matching push event
before proceeding. Do not replace missing results with a fixed sleep or retry
count. Watch the exact Source lint and development-environment run IDs from the
same commit as well. Require successful `Repository`, `lint / Source lint` and
`Development environment` check runs from app 15368, plus successful
`ci/woodpecker/push/plugin` and `ci/woodpecker/push/site` statuses. A PR success
belongs to its PR head and does not establish acceptance of the squash SHA.
Retain the commit, run URLs and native pipeline URLs. Fix a failed merged
candidate through a new pull request before tagging.

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

Woodpecker 3.x reads `network_mode: none` as a direct step field; placing it
under `backend_options.docker` is ignored by the agent. Docker backend options
retain the ordinary `10042:10042` user. The server must accept the legacy
step-level field in its workflow schema. Verify the actual plugin container has
`HostConfig.NetworkMode=none` and no attached workflow network before claiming
offline acceptance; YAML lint and source assertions alone do not prove this.
Preparation and cloning retain their network access and public immutable inputs.


[Woodpecker](https://woodpecker.bolens.dev/repos) runs the plugin archive,
ShellCheck, behavior, strict QML controls and complete canonical headless runtime
suite on pull requests and pushes to `main`. Its pinned toolchain and v4.0.1
imports also serve retained GitHub callers. Preparation runs
`bash scripts/woodpecker-plugin.sh --prepare` to fetch immutable public imports
and install the tracked locked site-test dependencies with `npm ci --ignore-scripts`.
The required `--offline` phase runs as container user 10042 with networking
disabled; the Qt toolchain is already in the image. Neither phase
receives publishing secrets.

Require `ci/woodpecker/pr/plugin` for ordinary pull requests, alongside the
existing Repository, source-lint, and development-environment checks. GitHub
retains full plugin validation for reusable callers by default through the typed
`release_validation` input; the signed-release workflow explicitly enables it.
Ordinary PR and main workflows skip the duplicate hosted plugin jobs.

Repository links, HTML/XML, workflow security, compatibility
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

Require `ci/woodpecker/pr/site` alongside the native plugin and existing hosted
checks. Ordinary PR and main runs use the pinned native browser audit; GitHub
continues the site build, structure, HTML/XML, link, and workflow-security checks.
Reusable callers retain hosted browser validation through `release_validation`
with its default `true`; signed releases explicitly enable it. Manual GitHub
workflow dispatch also retains the hosted audit, and Woodpecker supports a manual
site run. Forks still require native approval and receive no publishing secrets.

Publishing and platform checks retain their current workflows. Review the manual
browser-image digest pin alongside the other native image pins; Dependabot does
not update Woodpecker YAML.

## QML compatibility profiles

After the Qt 6.12 compatibility update, stale plugin code may survive a hot reload.
Finish active captures, then run `omarchy restart shell` if old code or warnings
remain. See [Omarchy #6981](https://github.com/omacom/omarchy/issues/6981) for the
upstream cache issue and restart workaround.

Refresh the source and tooling profiles with the toolchain. Verify every imported
file against its immutable upstream source and keep the palette backport and
metadata projection explicit. Require real valid/invalid lint controls and the
complete existing runtime inventory before accepting a new profile. Preserve the
older/current palette and token-engine comparison as compatibility evidence.
Update native, retained release-validation and compatibility image digests only
after the actual published image has passed admission. Keep these maintainer
helpers out of the release archive through the existing `scripts/` and `tests/`
export exclusions; release validation still checks the actual distributable.

## Additive native repository checks

The credential-free `repository` workflow adds the existing shared Source lint,
workflow security, changelog, HTML/XML and documentation-link policies on each
PR, main push and manual native run. It builds/tests the site for link discovery;
the separate `site` workflow retains the actual Lighthouse accessibility audit.
Privacy-specific issue-form, release metadata and docs checks remain mandatory
where applicable. Run `bash scripts/woodpecker-repository.sh` in the documented
Linux tooling container to reproduce the public-tool bootstrap and checks.

Existing GitHub requirements remain active during this additive delivery. Do not
retire `Repository` or `lint / Source lint` until exact-head native PR and genuine
main proof is accepted and protected checks are migrated separately. Preserve
`ci.yml`'s reusable release-validation interface and all release, platform and
Pages deployment boundaries. No future pipeline or merge is accepted by this text.
