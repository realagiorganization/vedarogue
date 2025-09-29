#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


def normalize(s: str) -> str:
    # Collapse whitespace and punctuation spaces; keep Devanagari chars
    s = re.sub(r"\s+", " ", s, flags=re.UNICODE)
    s = s.strip()
    return s


def snippet(s: str, n: int = 24) -> str:
    s = normalize(s)
    return s[:n]


def main():
    ap = argparse.ArgumentParser(description="Compare OCR/extracted PDF text to expected verses")
    ap.add_argument('--expected', default='build/verses.json', help='JSON file with expected rows (verse, translation)')
    ap.add_argument('--txt', default='build/verses.txt', help='Extracted text from PDF')
    ap.add_argument('--require-translation', action='store_true', help='Fail if translations are missing or not found')
    args = ap.parse_args()

    expected_rows = json.loads(Path(args.expected).read_text())
    pdf_text = Path(args.txt).read_text(encoding='utf-8', errors='ignore')
    norm_pdf = normalize(pdf_text)

    misses = []
    for r in expected_rows:
        v = r.get('verse') or ''
        t = r.get('translation') or ''
        v_snip = snippet(v)
        if v_snip and v_snip not in norm_pdf:
            misses.append({'type': 'verse', 'snippet': v_snip})
        if args.require-translation:
            t_snip = snippet(t) if t else ''
            if t_snip and t_snip not in norm_pdf:
                misses.append({'type': 'translation', 'snippet': t_snip})

    if misses:
        print("Missing expected snippets in PDF text:")
        for m in misses[:10]:
            print(f" - {m['type']}: '{m['snippet']}'")
        raise SystemExit(f"FAIL: {len(misses)} snippet(s) not found")

    print(f"PASS: All {len(expected_rows)} verse snippets found in PDF text")


if __name__ == '__main__':
    main()

