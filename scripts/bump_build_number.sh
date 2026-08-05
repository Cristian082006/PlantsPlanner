#!/bin/bash
# Increments the build number (the part after "+") in pubspec.yaml's
# version line, leaving the semantic version (major.minor.patch) untouched.
# Run before every phone install so each build is distinguishable in
# Settings > Versiune aplicație.
set -euo pipefail

cd "$(dirname "$0")/.."

current=$(grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//')
name="${current%%+*}"
build="${current##*+}"
next_build=$((build + 1))
new_version="${name}+${next_build}"

sed -i '' "s/^version:.*/version: ${new_version}/" pubspec.yaml
echo "version: ${current} -> ${new_version}"
