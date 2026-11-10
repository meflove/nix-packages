#!/usr/bin/env bash
# Build the given flake package attributes and push each one to Cachix.
#
# Usage: bash .tangled/scripts/build-and-push.sh <pkg>...
#
# Pushes happen per package, so a workflow that runs out of time still leaves
# everything it did build in the cache. A failing package is reported and
# skipped — the rest of the list still builds.
set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <pkg>..." >&2
  exit 2
fi

failed=()
for pkg in "$@"; do
  echo "building and pushing $pkg"
  # pipefail makes the pipeline report nix's status; without it a failed build
  # produced empty stdin for cachix and the old `|| echo` never triggered.
  if ! nix build -L --no-link --print-out-paths ".#legacyPackages.x86_64-linux.$pkg" | cachix push meflove; then
    echo "WARN: failed $pkg, skipping" >&2
    failed+=("$pkg")
  fi
done

if [ "${#failed[@]}" -gt 0 ]; then
  echo "WARN: failed packages: ${failed[*]}" >&2
fi
