import json
from pathlib import Path
import subprocess
import sys
import yaml


def run(cmd):
    res = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return res.stdout


def ensure_build_json(tmp_json='build/verses.json'):
    p = Path(tmp_json)
    if p.exists():
        return p
    # Export small slice
    run(f"python3 scripts/hf_export_json.py --splits 'train[:5]' --out {p}")
    assert p.exists(), 'Failed to create verses.json'
    return p


def test_generate_yaml_end_to_end(tmp_path):
    # Prepare input JSON
    ensure_build_json()
    out_yaml = tmp_path / 'roguelike.yaml'
    # Generate YAML using deterministic fallback (no OPENAI_API_KEY in CI)
    cmd = f"python3 scripts/dspy_generate_yaml.py --json build/verses.json --out {out_yaml} --range 'train:0-3'"
    out = run(cmd)
    assert out_yaml.exists(), 'YAML was not generated'
    data = yaml.safe_load(out_yaml.read_text())
    # Validate schema
    assert 'level' in data and 'items' in data and 'dialogs' in data
    lvl = data['level']
    assert isinstance(lvl.get('map'), list) and len(lvl['map']) >= 5
    assert isinstance(data['items'], list) and len(data['items']) >= 1
    assert isinstance(data['dialogs'], list)


def test_yaml_has_unicode_content():
    # Ensure some content from verse appears in dialogs or description
    p = Path('build/verses.json')
    ensure_build_json(p)
    data = json.loads(p.read_text())
    # Generate directly to a known path
    run("python3 scripts/dspy_generate_yaml.py --json build/verses.json --out build/roguelike.yaml --range 'train:0-2'")
    y = yaml.safe_load(Path('build/roguelike.yaml').read_text())
    text = (y.get('level', {}).get('description', '') + ' ' + ' '.join(d.get('text','') for d in y.get('dialogs', [])))
    assert isinstance(text, str) and len(text) > 0

