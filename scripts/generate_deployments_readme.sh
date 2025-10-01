#!/usr/bin/env bash
set -euo pipefail

# Generates README.deployments.md summarizing the current GitHub Actions run:
# - Run metadata
# - Artifacts produced (queried via GitHub API)
# - Docker images present in this job (repository:tag, id, size)
# Writes to repo root as README.deployments.md

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OUT_FILE="$ROOT_DIR/README.deployments.md"

REPO="${GITHUB_REPOSITORY:-}"
RUN_ID="${GITHUB_RUN_ID:-}"
SHA="${GITHUB_SHA:-$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo)}"
REF="${GITHUB_REF:-$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo)}"
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/$REPO/actions/runs/$RUN_ID"
TOKEN="${GITHUB_TOKEN:-${ACTIONS_RUNTIME_TOKEN:-}}"

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

header() {
  cat <<HDR
# Deployments & Build Catalog

Generated: $(timestamp) UTC
Repository: ${REPO:-unknown}
Commit: ${SHA:-unknown}
Ref: ${REF:-unknown}
Run: ${RUN_ID:-unknown}
Run URL: ${RUN_URL}

HDR
}

list_artifacts_json() {
  [ -n "$REPO" ] && [ -n "$RUN_ID" ] || { echo '{}' ; return; }
  if [ -z "$TOKEN" ]; then
    curl -fsSL "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts"
  else
    curl -fsSL -H "Authorization: Bearer $TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts"
  fi
}

artifacts_md() {
  python3 - "$@" <<'PY'
import json,sys
data=json.load(sys.stdin)
arts=data.get('artifacts', []) if isinstance(data,dict) else []
print('## Artifacts')
if not arts:
    print('- (none found or not accessible)')
else:
    for a in arts:
        name=a.get('name','')
        size=a.get('size_in_bytes',0)
        expired=a.get('expired',False)
        url=a.get('archive_download_url','')
        print(f"- {name} — {size} bytes — expired={expired} — download: {url}")
PY
}

docker_images_md() {
  echo "## Docker Images (this job)"
  if ! command -v docker >/dev/null 2>&1; then
    echo "- Docker not available in this job."
    return
  fi
  # Print notable images first, then a compact list of all
  notable=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' \
    | grep -E '(^make-runner:|tui-(win|wsl):|vedarogue/)' || true)
  if [ -n "$notable" ]; then
    echo "$notable" | sed 's/^/- /'
  else
    echo "- (no notable images found)"
  fi
  echo "\n<details><summary>All images</summary>"
  docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' | sed 's/^/- /'
  echo "</details>"
}

{
  header
  echo "## Overview"
  echo "This document catalogs build artifacts and Docker images produced during the GitHub Actions run."
  echo
  list_artifacts_json | artifacts_md
  echo
  docker_images_md
} > "$OUT_FILE"

echo "Wrote $OUT_FILE"

