#!/usr/bin/env bash
set -euo pipefail

# Auto-commit and push with a meaningful message including README changelogs
# and snippets from docker interactive outputs (from build/test_logs).

SUBJECT=${1:-"chore: update"}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

git config user.email >/dev/null 2>&1 || git config user.email "codex-bot@example.com"
git config user.name >/dev/null 2>&1 || git config user.name "codex-bot"

# Detect changes
if git diff --quiet --exit-code; then
  echo "No changes to commit."
  exit 0
fi

# Gather README changes
README_CHANGES=$(git diff --name-only | grep -E '^README.*\.md$|.*/README.*\.md$' || true)

compose_readme_block() {
  if [ -z "$README_CHANGES" ]; then
    echo "README updates: (none)"
    return
  fi
  echo "README updates:"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # Grab first non-empty line as a rough one-line summary
    summary=$(grep -m1 -vE '^\s*$' "$f" | sed -e 's/[#*`\-]//g' -e 's/\r//g' | cut -c1-120)
    echo "- $f: ${summary:-updated}"
  done <<< "$README_CHANGES"
}

# Include examples of interactive screen output captured from docker tests
compose_docker_examples() {
  local logdir="build/test_logs"
  echo "\nDocker interactive output examples:"
  if [ ! -d "$logdir" ]; then
    echo "- (no logs present)"
    return
  fi
  shopt -s nullglob
  for f in "$logdir"/*.out.txt "$logdir"/*.err.txt; do
    bn=$(basename "$f")
    echo "- $bn (first 20 lines):"
    sed -n '1,20p' "$f" | sed 's/^/  | /'
  done
}

COMMIT_MSG=$(cat <<MSG
$SUBJECT

$(compose_readme_block)

$(compose_docker_examples)
MSG
)

git add -A
echo "$COMMIT_MSG" | git commit -F -
git push
echo "Pushed with message:\n$COMMIT_MSG"

