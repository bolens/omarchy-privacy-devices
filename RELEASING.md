# Releasing

1. Update `manifest.json` with the new semantic version.
2. Move relevant entries from `Unreleased` into a dated version section in
   `CHANGELOG.md` and update its comparison links.
3. Run the validation commands documented in `CONTRIBUTING.md`.
4. Merge the release preparation through a pull request and confirm the
   required `Plugin` and `Repository` checks pass.
5. Create and push an annotated `vX.Y.Z` tag from the validated commit.
6. Confirm the Release workflow publishes the source archive and SHA-256
   checksum.
7. Verify the Pages site displays the new version and the official plugin
   directory reflects the release.

The Release workflow rejects tags that do not match the manifest version and
re-runs validation before publishing.
