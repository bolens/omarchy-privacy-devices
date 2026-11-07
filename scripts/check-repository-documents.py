#!/usr/bin/env python3
"""Preserve the hosted repository HTML/XML/link policy in native CI."""
import argparse
from pathlib import Path
import subprocess
import sys

REPOSITORIES = {"omarchy-app-drawer", "omarchy-multi-monitor-workspaces",
                "omarchy-p2p-services", "omarchy-privacy-devices"}


def check_tidy(run=subprocess.run):
    result = run(["tidy", "-errors", "-quiet", "docs/index.html", "docs/404.html"],
                 text=True, capture_output=True, check=False)
    output = result.stdout + result.stderr
    print(output, end="")
    # Tidy returns 1 for warnings and 2 for errors. Unexpected execution failures
    # must fail even when no familiar diagnostic was printed.
    if result.returncode not in (0, 1) or "Error:" in output:
        raise RuntimeError("HTML validation failed")


def link_command(repository, lychee):
    if repository not in REPOSITORIES:
        raise ValueError("unsupported repository")
    compare = (rf"^https://github\.com/bolens/{repository}/compare/"
               if repository == "omarchy-privacy-devices" else
               rf"^https://github\.com/bolens/{repository}/(compare|releases/tag)/")
    return [lychee, "--no-progress", "--exclude-path", "(^|/)node_modules/",
            "--accept", "200,204,206,429", "--exclude", compare, "--exclude",
            rf"^https://bolens[.]github[.]io/{repository}/changelog/$",
            "./**/*.md", "./_site/**/*.html"]


def check_documents(repository, lychee="lychee", run=subprocess.run):
    if not Path("_site/index.html").is_file():
        raise RuntimeError("build the site before checking repository links")
    check_tidy(run)
    run(["xmllint", "--noout", "docs/favicon.svg", "docs/sitemap.xml"], check=True)
    run(link_command(repository, lychee), check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", choices=sorted(REPOSITORIES), required=True)
    parser.add_argument("--lychee", default="lychee")
    args = parser.parse_args()
    check_documents(args.repository, args.lychee)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
