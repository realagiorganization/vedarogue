#!/usr/bin/env bash
set -euo pipefail

# Auto-commit changes by watching the filesystem and generating a commit message.
# - Uses `fswatch` if available (macOS/Linux); falls back to a simple polling loop.
# - Tries to use `codex` or `codex-cli` to generate a concise Conventional Commit message.
# - Falls back to interactive prompt if codex CLI is unavailable.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "Error: Not inside a git repository." >&2
  exit 1
fi
cd "${REPO_ROOT}"

WATCH_PATHS=(".")
[[ $# -gt 0 ]] && WATCH_PATHS=("$@")

# Exclusions (regex for fswatch) — keep events tidy
FS_EXCLUDES=(
  '\\.git/'
  '\\./build/'
  '\\./data/'
)

# Detect codex CLI
CODEX_CMD=""
if command -v codex >/dev/null 2>&1; then
  CODEX_CMD="codex"
elif command -v codex-cli >/dev/null 2>&1; then
  CODEX_CMD="codex-cli"
fi

gen_commit_message() {
  # Stage everything first so diffs are deterministic for the prompt
  git add -A >/dev/null
  if ! git diff --staged --quiet; then
    :
  else
    # Nothing to commit
    return 1
  fi

  local files stat prompt out msg
  files=$(git diff --staged --name-status)
  stat=$(git diff --staged --stat)
  prompt=$(cat <<'EOF'
You are an expert commit message generator.
Given the staged changes (file list and diffstat), output a single-line Conventional Commit subject (max 72 chars). Be concise and informative. No trailing period. No body.
EOF
  )
  prompt+=$'\n\nFiles:\n'
  prompt+="${files}"
  prompt+=$'\n\nStat:\n'
  prompt+="${stat}"

  msg=""
  if [[ -n "${CODEX_CMD}" ]]; then
    # Try a few common invocation styles; capture first line of output
    if out=$(printf "%s\n" "$prompt" | ${CODEX_CMD} ask 2>/dev/null || true); then
      msg=$(printf "%s\n" "$out" | head -n1 | sed -e 's/^\s*//' -e 's/\s*$//')
    fi
    if [[ -z "$msg" ]]; then
      if out=$(printf "%s\n" "$prompt" | ${CODEX_CMD} 2>/dev/null || true); then
        msg=$(printf "%s\n" "$out" | head -n1 | sed -e 's/^\s*//' -e 's/\s*$//')
      fi
    fi
  fi

  if [[ -z "$msg" ]]; then
    echo "Enter commit subject (or leave empty to skip):" >&2
    read -r msg || true
  fi

  if [[ -z "$msg" ]]; then
    echo "Skipping commit (no message)." >&2
    return 1
  fi

  # Ensure single-line subject and trim length (hard cut to 72 chars)
  msg=$(printf "%s" "$msg" | head -n1)
  msg=${msg:0:72}

  printf "%s\n" "$msg"
  return 0
}

commit_once() {
  if ! git diff --quiet || ! git diff --staged --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    local subject
    if subject=$(gen_commit_message); then
      git commit -m "$subject" && echo "Committed: $subject"
      return 0
    else
      # If nothing staged or user skipped, just return
      return 0
    fi
  fi
  return 0
}

run_fswatch() {
  echo "watch_autocommit: using fswatch at ${REPO_ROOT}" >&2
  local args=(-or)
  for ex in "${FS_EXCLUDES[@]}"; do
    args+=(--exclude "$ex")
  done
  args+=("${WATCH_PATHS[@]}")
  fswatch "${args[@]}" | while read -r _; do
    commit_once || true
    # Debounce a bit
    sleep 1
  done
}

run_poll() {
  echo "watch_autocommit: fswatch not found; falling back to polling" >&2
  while true; do
    if ! git diff --quiet || ! git diff --staged --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
      commit_once || true
      sleep 1
    else
      sleep 2
    fi
  done
}

trap 'echo "Exiting watch_autocommit" >&2; exit 0' INT TERM

if command -v fswatch >/dev/null 2>&1; then
  run_fswatch
else
  run_poll
fi

