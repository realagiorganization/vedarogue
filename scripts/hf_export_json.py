#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path


def main():
    try:
        from datasets import load_dataset
    except Exception as e:
        print("The 'datasets' package is required. Run: make setup", flush=True)
        raise

    p = argparse.ArgumentParser(description="Export HF dataset rows to a JSON array usable by Emacs script")
    p.add_argument('--dataset', default=os.environ.get('HF_DATASET_ID', 'manojbalaji1/anveshana'))
    p.add_argument('--splits', default=os.environ.get('HF_SPLITS', 'train[:10]'), help='Comma-separated split selectors (e.g., train[:10],validation[:5])')
    p.add_argument('--revision', default=os.environ.get('HF_REVISION', ''))
    p.add_argument('--token', default=os.environ.get('HF_TOKEN', os.environ.get('HUGGINGFACE_TOKEN', '')))
    p.add_argument('--out', default='build/verses.json')
    args = p.parse_args()

    kwargs = {}
    if args.revision:
        kwargs['revision'] = args.revision
    if args.token:
        # support both tokens depending on installed datasets version
        try:
            _ = load_dataset(args.dataset, split='train[:1]', token=args.token)
            kwargs['token'] = args.token
        except TypeError:
            kwargs['use_auth_token'] = args.token

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)

    all_rows = []
    for spec in [s.strip() for s in args.splits.split(',') if s.strip()]:
        # split spec may include slicing; extract base split name for labelling
        base_split = spec.split('[')[0]
        ds = load_dataset(args.dataset, split=spec, **kwargs)
        for i, row in enumerate(ds):
            verse = row.get('verse') or row.get('document') or ''
            translation = row.get('translation') or ''
            all_rows.append({
                'split': base_split,
                'index': i,
                'verse': verse,
                'translation': translation,
            })

    out.write_text(json.dumps(all_rows, ensure_ascii=False, indent=2))
    print(f"Wrote {len(all_rows)} rows to {out}")


if __name__ == '__main__':
    main()

