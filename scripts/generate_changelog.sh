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
  echo "### Imaginary Screenshots (80x80)"
  # Detect TUIs added/changed in range (install_tui/*.sh)
  tuis=$(git diff --name-status $range | awk '/install_tui\/.*\.sh$/ {print $2}' | sed 's#.*/##; s/\.sh$//' | sort -u)
  if [ -z "$tuis" ]; then
    echo "- (no TUIs changed)"
  else
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      echo
      echo "#### $name"
      echo '```
'
      # Generate an 80x80 pseudographic box for the TUI
      python3 - "$name" <<'PY'
import sys
name=sys.argv[1]
W=80; H=80
def pad(s):
    return s[:W] + ' '*(W-len(s)) if len(s)<W else s[:W]
# precompose a grid
grid=[[' ']*W for _ in range(H)]
def hline(r,c1,c2,ch='─'):
    for c in range(c1,c2+1): grid[r][c]=ch
def vline(c,r1,r2,ch='│'):
    for r in range(r1,r2+1): grid[r][c]=ch
def text(r,c,s):
    for i,ch in enumerate(s):
        if 0<=c+i<W: grid[r][c+i]=ch

# border
grid[0][0]='┌'; grid[0][-1]='┐'; grid[-1][0]='└'; grid[-1][-1]='┘'
hline(0,1,W-2)
hline(H-1,1,W-2)
vline(0,1,H-2)
vline(W-1,1,H-2)

title=f" TUI: {name}  |  j/k: move  q: quit  ?: help"
text(1,2,title[:W-4])
hline(2,1,W-2)

# layout: left pane, right pane split
mid= int(W*0.55)
vline(mid,3,H-2)
text(3,2,"Files")
text(3,mid+2,"Preview")
hline(4,1,W-2,'─')

# draw some file rows with selection indicator
rows=list("▏  ..\n▏  bin/\n▏  etc/\n▏  home/\n▏  usr/\n▏  var/\n▏  tmp/\n▏  README.md\n▏  Makefile\n▏  install_tui/\n▏  scripts/\n▏  docker/\n").split("\n")
for i,r in enumerate(rows):
    rr=5+i
    if rr>=H-2: break
    line=f" {r}"
    if i==3:
        # highlight selection
        text(rr,1,'▌')
        text(rr,3,line)
    else:
        text(rr,2,line)

# right pane sample
for rr in range(6, min(H-3, 40)):
    text(rr, mid+2, "│ Lorem ipsum dolor sit amet, consectetur adipiscing elit.")

# footer status
status=f" {name}  |  / search  : cmd  ⓘ status OK"
text(H-2,2,status[:W-4])

for r in range(H):
    print(''.join(grid[r]))
PY
      echo '
```'
    done <<< "$tuis"
  fi
  echo
  if [ -f "$OUT" ]; then
    # Append previous content
    awk 'NR>1{print prev} {prev=$0} END{print prev}' "$OUT" | sed '1d'
  fi
} > "$OUT.tmp"

mv "$OUT.tmp" "$OUT"
echo "Updated $OUT for range $range"
