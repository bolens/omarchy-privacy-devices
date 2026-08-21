#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output_dir="$repo_root/_site"
version=$(node -e 'const version = require(process.argv[1]).version; if (!/^\d+\.\d+\.\d+([+-].*)?$/.test(version)) process.exit(1); process.stdout.write(version)' "$repo_root/manifest.json")
last_modified=$(git -C "$repo_root" log -1 --format=%cs -- docs manifest.json)

rm -rf "$output_dir"
cp -R "$repo_root/docs" "$output_dir"
cp "$repo_root/manifest.json" "$output_dir/manifest.json"

sed -i "s/__PLUGIN_VERSION__/$version/g" "$output_dir/index.html"
sed -i "s|</url>|    <lastmod>$last_modified</lastmod>\n  </url>|" "$output_dir/sitemap.xml"
