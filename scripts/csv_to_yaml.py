#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

def main(csv_path: str, yaml_path: str) -> int:
    rows = []
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append({k: v for k, v in r.items()})

    out = Path(yaml_path)
    out.parent.mkdir(parents=True, exist_ok=True)

    with open(out, 'w', encoding='utf-8') as f:
        f.write('tests:\n')
        for r in rows:
            f.write('  - name: "{}"\n'.format(r.get('name','')))
            f.write('    image: "{}"\n'.format(r.get('image','')))
            f.write('    command: "{}"\n'.format(r.get('command','').replace('"','\"')))
            f.write('    exit_code: {}\n'.format(r.get('exit_code','0')))
            f.write('    duration_ms: {}\n'.format(r.get('duration_ms','0')))
            f.write('    stdout_file: "{}"\n'.format(r.get('stdout_file','')))
            f.write('    stderr_file: "{}"\n'.format(r.get('stderr_file','')))
            f.write('    server_os: "{}"\n'.format(r.get('server_os','')))
    print(f"Wrote {yaml_path}")
    return 0

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: csv_to_yaml.py <in.csv> <out.yaml>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))

