#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import List, Dict, Any

# Ensure project root on path when running from scripts/
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

from rl_dspy.roguelike_generator import RoguelikeGenerator


def parse_range(range_str: str | None):
    if not range_str:
        return None
    parts = range_str.split(":")
    split = parts[0] if len(parts) > 1 else None
    rest = parts[-1]
    if "-" in rest:
        start_s, end_s = rest.split("-", 1)
    else:
        start_s = end_s = rest
    return {
        'split': split,
        'start': int(start_s),
        'end': int(end_s),
    }


def filter_rows(rows: List[Dict[str, Any]], r: dict | None) -> List[Dict[str, Any]]:
    if r is None:
        return rows
    split = r.get('split')
    start = r.get('start', 0)
    end = r.get('end', 0)
    out = []
    for row in rows:
        if split and row.get('split') != split:
            continue
        idx = row.get('index')
        if isinstance(idx, int) and start <= idx <= end:
            out.append(row)
    return out


def main():
    ap = argparse.ArgumentParser(description="Generate Roguelike YAML from verses JSON using DSPy or fallback")
    ap.add_argument('--json', default='build/verses.json')
    ap.add_argument('--out', default='build/roguelike.yaml')
    ap.add_argument('--range', dest='range_str', default=None, help="Range like train:0-9")
    ap.add_argument('--guidelines', default='', help='Extra constraints to pass to the generator')
    args = ap.parse_args()

    rows = json.loads(Path(args.json).read_text())
    sel = filter_rows(rows, parse_range(args.range_str))
    if not sel:
        raise SystemExit("No rows selected; check --range and JSON contents")

    gen = RoguelikeGenerator()
    yaml_text = gen.generate_yaml(sel, guidelines=args.guidelines)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(yaml_text, encoding='utf-8')
    print(f"Wrote roguelike YAML: {out}")


if __name__ == '__main__':
    main()
