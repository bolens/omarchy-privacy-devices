#!/usr/bin/env bash
# Networked public tooling/doc policy; separate from mandatory offline QML CI.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
repository=omarchy-privacy-devices
mode=${1:---all}
[[ $# -le 1 ]] || exit 2
case "$mode" in --policy|--documents|--all) ;; *) echo "Usage: woodpecker-repository.sh [--policy|--documents|--all]" >&2; exit 2 ;; esac
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
mkdir "$scratch/bin"
export PATH="$scratch/bin:$PATH"
if [[ $mode != --documents ]]; then
python3 -m venv "$scratch/venv"
"$scratch/venv/bin/pip" install --disable-pip-version-check ruff==0.15.20 zizmor==1.29.0
export PATH="$scratch/venv/bin:$scratch/bin:$PATH"
# The exact shared implementation used by the existing required Source lint job.
revision=7603518f305fb76f7bb1b9979f2692521f633b82
git init --quiet "$scratch/source-tooling"
GIT_TERMINAL_PROMPT=0 git -C "$scratch/source-tooling" fetch --quiet --depth 1 https://github.com/bolens/.github.git "$revision"
git -C "$scratch/source-tooling" checkout --quiet --detach FETCH_HEAD
[[ $(git -C "$scratch/source-tooling" rev-parse HEAD) == "$revision" ]]
npm ci --ignore-scripts --no-audit --no-fund --prefix "$scratch/source-tooling/tools/source-lint"
python3 "$scratch/source-tooling/scripts/lint-source.py" "$PWD"
# Match the existing immutable shared workflow and accepted native peer tools.
curl --fail --silent --show-error --location --retry 3 --output "$scratch/actionlint.tar.gz" https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz
printf '%s  %s\n' 8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8 "$scratch/actionlint.tar.gz" | sha256sum --check --strict
tar -xzf "$scratch/actionlint.tar.gz" -C "$scratch/bin" actionlint
actionlint
zizmor --offline --min-severity medium --min-confidence medium .github
python3 scripts/check-changelog.py
fi
if [[ $mode != --policy ]]; then
python3 -m unittest discover -s tests -p test_native_repository_documents.py
curl --fail --silent --show-error --location --retry 3 --output "$scratch/lychee.tar.gz" https://github.com/lycheeverse/lychee/releases/download/lychee-v0.24.2/lychee-x86_64-unknown-linux-gnu.tar.gz
printf '%s  %s\n' 1f4e0ef7f6554a6ed33dd7ac144fb2e1bbed98598e7af973042fc5cd43951c9a "$scratch/lychee.tar.gz" | sha256sum --check --strict
# Extract only the verified regular executable, never archive paths or symlinks.
python3 - "$scratch/lychee.tar.gz" "$scratch/bin/lychee" <<'PYTOOL'
import os
import sys
import tarfile
with tarfile.open(sys.argv[1], "r:gz") as archive:
    matches = [member for member in archive.getmembers() if member.name == "lychee-x86_64-unknown-linux-gnu/lychee"]
    if len(matches) != 1 or not matches[0].isfile() or not 0 < matches[0].size < 32 * 1024 * 1024:
        raise SystemExit("unexpected pinned Lychee executable")
    with archive.extractfile(matches[0]) as source, open(sys.argv[2], "xb") as output:
        output.write(source.read())
os.chmod(sys.argv[2], 0o755)
PYTOOL
npm ci --ignore-scripts --no-audit --no-fund
ruby scripts/validate-issue-forms.rb
node tests/release.test.js
npm run test:docs
npm run build:site
npm run test:site
python3 scripts/check-repository-documents.py --repository "$repository"
fi
