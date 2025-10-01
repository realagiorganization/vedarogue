#!/usr/bin/env bash
set -euo pipefail

# Generate release body markdown between previous tag and current HEAD (tagged commit in CI)

prev_tag=$(git tag --list --sort=creatordate | tail -n2 | head -n1)
curr_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
range=""
if [ -n "$prev_tag" ] && [ -n "$curr_tag" ] && [ "$prev_tag" != "$curr_tag" ]; then
  range="$prev_tag..$curr_tag"
else
  range="HEAD~50..HEAD"
fi

echo "## Changes"
git log --pretty=format:'- %s (%h)' $range || echo "- (no changes)"
echo
echo "## Artifacts"
echo "- See attached docker test logs and deployments catalog."

