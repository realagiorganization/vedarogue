#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

OUT=CHANGELOG.md
DATE=$(date -u +"%Y-%m-%d")

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
range=""
if [ -n "$last_tag" ]; then
  range="$last_tag..HEAD"
else
  # from first commit
  first=$(git rev-list --max-parents=0 HEAD | tail -n1)
  range="$first..HEAD"
fi

readme_changes=$(git diff --name-only $range | grep -E '^README.*\.md$|.*/README.*\.md$' || true)

commits=$(git log --pretty=format:'- %s (%h)' $range)

{
  echo "# Changelog"
  echo
  if [ -f "$OUT" ]; then
    # Print existing content below new section
    :
  fi
  echo "## Unreleased - $DATE"
  echo
  if [ -n "$readme_changes" ]; then
    echo "### README updates"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      echo "- $f"
    done <<< "$readme_changes"
    echo
  fi
  echo "### Commits"
  if [ -n "$commits" ]; then
    echo "$commits"
  else
    echo "- (no changes)"
  fi
  echo
  if [ -f "$OUT" ]; then
    # Append previous content
    awk 'NR>1{print prev} {prev=$0} END{print prev}' "$OUT" | sed '1d'
  fi
} > "$OUT.tmp"

mv "$OUT.tmp" "$OUT"
echo "Updated $OUT for range $range"

