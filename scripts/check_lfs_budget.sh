#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OUT_DIR="$ROOT_DIR/build/lfs_report"
mkdir -p "$OUT_DIR"

SUMMARY_MD="$OUT_DIR/summary.md"
LFS_CSV="$OUT_DIR/lfs_tracked.csv"
WORKTREE_CSV="$OUT_DIR/large_worktree_files.csv"
HISTORY_CSV="$OUT_DIR/large_history_blobs.csv"

MAX_WORKTREE_WARN=${MAX_WORKTREE_WARN:-10485760}   # 10 MB
MAX_WORKTREE_FAIL=${MAX_WORKTREE_FAIL:-52428800}   # 50 MB
MAX_HISTORY_WARN=${MAX_HISTORY_WARN:-10485760}
MAX_HISTORY_FAIL=${MAX_HISTORY_FAIL:-52428800}

fail=0

echo "repo=$ROOT_DIR" > "$SUMMARY_MD"
echo "generated=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$SUMMARY_MD"
echo >> "$SUMMARY_MD"

# LFS tracked files (if git-lfs present)
echo "name,oid,size" > "$LFS_CSV"
if command -v git >/dev/null 2>&1 && git lfs version >/dev/null 2>&1; then
  git lfs ls-files -l | awk '{print $2","$1","$3}' >> "$LFS_CSV" || true
  lfs_count=$(wc -l < "$LFS_CSV" | awk '{print $1-1}')
  echo "lfs_tracked_count=$lfs_count" >> "$SUMMARY_MD"
else
  echo "lfs_tracked_count=0 (git-lfs unavailable)" >> "$SUMMARY_MD"
fi

# Large worktree files
echo "path,size_bytes" > "$WORKTREE_CSV"
if command -v find >/dev/null 2>&1; then
  while IFS= read -r f; do
    sz=$(stat -f %z "$f" 2>/dev/null || stat -c %s "$f" 2>/dev/null || echo 0)
    echo "$f,$sz" >> "$WORKTREE_CSV"
  done < <(find "$ROOT_DIR" -type f \( -path "$ROOT_DIR/.git/*" -prune -o -print \) | sed -e "s#^$ROOT_DIR/##" -e "/^\.git\//d")
fi

work_warn=$(awk -F, -v T=$MAX_WORKTREE_WARN 'NR>1 && $2+0>T {c++} END{print c+0}' "$WORKTREE_CSV")
work_fail=$(awk -F, -v T=$MAX_WORKTREE_FAIL 'NR>1 && $2+0>T {c++} END{print c+0}' "$WORKTREE_CSV")
echo "worktree_warn_count=$work_warn (>${MAX_WORKTREE_WARN}B)" >> "$SUMMARY_MD"
echo "worktree_fail_count=$work_fail (>${MAX_WORKTREE_FAIL}B)" >> "$SUMMARY_MD"
if [ "$work_fail" -gt 0 ]; then fail=1; fi

# Large blobs in history (top 50)
echo "oid,size_bytes,path" > "$HISTORY_CSV"
if command -v git >/dev/null 2>&1; then
  git rev-list --objects --all |
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
    awk '$1=="blob" {print $2","$3","$4}' |
    sort -t, -k2,2nr | head -n 50 >> "$HISTORY_CSV" || true
fi

hist_warn=$(awk -F, -v T=$MAX_HISTORY_WARN 'NR>1 && $2+0>T {c++} END{print c+0}' "$HISTORY_CSV")
hist_fail=$(awk -F, -v T=$MAX_HISTORY_FAIL 'NR>1 && $2+0>T {c++} END{print c+0}' "$HISTORY_CSV")
echo "history_warn_count=$hist_warn (>${MAX_HISTORY_WARN}B)" >> "$SUMMARY_MD"
echo "history_fail_count=$hist_fail (>${MAX_HISTORY_FAIL}B)" >> "$SUMMARY_MD"
if [ "$hist_fail" -gt 0 ]; then fail=1; fi

echo >> "$SUMMARY_MD"
echo "recommendations:" >> "$SUMMARY_MD"
echo "- Remove or compress large worktree files; avoid committing binaries and media directly." >> "$SUMMARY_MD"
echo "- Use external storage or artifacts; for docs, link instead of embedding large assets." >> "$SUMMARY_MD"
echo "- To reduce history: use BFG Repo-Cleaner or 'git filter-repo' to purge large blobs." >> "$SUMMARY_MD"
echo "- Configure .gitattributes thoughtfully; track only necessary types with LFS." >> "$SUMMARY_MD"

echo "wrote: $SUMMARY_MD"
echo "wrote: $LFS_CSV"
echo "wrote: $WORKTREE_CSV"
echo "wrote: $HISTORY_CSV"

if [ "${LFS_AUDIT_FAIL:-true}" = "true" ] && [ $fail -ne 0 ]; then
  echo "LFS budget check: FAIL (large files present)." >&2
  exit 1
else
  echo "LFS budget check: OK (or warnings only)."
fi

