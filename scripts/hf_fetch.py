#!/usr/bin/env python3
import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def ensure_datasets_installed():
    try:
        import datasets  # noqa: F401
    except Exception as e:
        eprint("The 'datasets' package is required. Install dependencies:")
        eprint("  python3 -m pip install -r requirements.txt")
        eprint(f"Import error: {e}")
        sys.exit(2)


def sanitize(name: str) -> str:
    return name.replace('/', '_').replace(' ', '_')


def export_split(ds, out_dir: Path, base_name: str, split_name: str):
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"{base_name}_{split_name}" if split_name else base_name
    parquet_path = out_dir / f"{stem}.parquet"
    # Use parquet for robustness (pyarrow is a dependency of datasets)
    ds.to_parquet(str(parquet_path))
    return str(parquet_path), len(ds)


def main():
    ensure_datasets_installed()
    from datasets import load_dataset
    from inspect import signature

    parser = argparse.ArgumentParser(description="Fetch a Hugging Face dataset and export to parquet")
    parser.add_argument('--dataset', required=True, help='HF dataset identifier, e.g. user/name')
    parser.add_argument('--dest', required=True, help='Destination directory for exported files')
    parser.add_argument('--splits', default='', help='Comma-separated splits to export (optional)')
    parser.add_argument('--revision', default='', help='Branch/tag/commit sha (optional)')
    parser.add_argument('--token', default=os.environ.get('HF_TOKEN') or os.environ.get('HUGGINGFACE_TOKEN', ''), help='Auth token (optional)')
    args = parser.parse_args()

    dataset_id = args.dataset
    revision = args.revision or None
    token = args.token or None
    out_dir = Path(args.dest)
    out_dir.mkdir(parents=True, exist_ok=True)

    base_name = sanitize(dataset_id)

    # Build kwargs for load_dataset
    kwargs = {}
    if revision:
        kwargs['revision'] = revision
    if token:
        # datasets recent versions accept 'token'; older accept 'use_auth_token'
        if 'token' in signature(load_dataset).parameters:
            kwargs['token'] = token
        else:
            kwargs['use_auth_token'] = token

    exported = []
    try:
        if args.splits.strip():
            splits = [s.strip() for s in args.splits.split(',') if s.strip()]
            for split in splits:
                ds = load_dataset(dataset_id, split=split, **kwargs)
                path, n = export_split(ds, out_dir, base_name, split)
                print(f"Exported {dataset_id}:{split} -> {path} ({n} rows)")
                exported.append({'split': split, 'path': path, 'rows': n})
        else:
            ds_dict = load_dataset(dataset_id, **kwargs)
            # ds_dict is a DatasetDict; iterate known splits
            for split, ds in ds_dict.items():
                path, n = export_split(ds, out_dir, base_name, split)
                print(f"Exported {dataset_id}:{split} -> {path} ({n} rows)")
                exported.append({'split': split, 'path': path, 'rows': n})
    except Exception as e:
        eprint(f"Failed to fetch dataset '{dataset_id}'.")
        if '401' in str(e) or '403' in str(e) or 'Unauthorized' in str(e):
            eprint("Authentication may be required. Use one of:")
            eprint("  - Run: huggingface-cli login")
            eprint("  - Or set env var HF_TOKEN=<your_token> when running the fetch")
        eprint(f"Error: {e}")
        sys.exit(1)

    meta = {
        'dataset': dataset_id,
        'revision': revision,
        'exported_at': datetime.utcnow().isoformat() + 'Z',
        'files': exported,
    }
    (out_dir / f"{base_name}_metadata.json").write_text(json.dumps(meta, indent=2))
    print(f"Wrote metadata: {(out_dir / f'{base_name}_metadata.json').as_posix()}")


if __name__ == '__main__':
    main()
