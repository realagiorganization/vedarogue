import json
import subprocess
import sys
from pathlib import Path

import yaml

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "build_blueprint.py"


def run_script(tmp_path: Path, rooms: int = 3) -> Path:
    sample_data = [
        {
            "book": "bg",
            "chapter": 1,
            "verse": idx + 1,
            "sanskrit": f"sample-sanskrit-{idx+1}",
            "translation": f"sample-translation-{idx+1}",
            "purport": f"sample-purport-{idx+1}",
        }
        for idx in range(max(rooms, 3))
    ]
    sample_path = tmp_path / "sample.json"
    sample_path.write_text(json.dumps(sample_data), encoding="utf-8")
    output_path = tmp_path / "blueprint.yaml"
    subprocess.run(
        [
            sys.executable,
            str(SCRIPT_PATH),
            "--vedabase-json",
            str(sample_path),
            "--output",
            str(output_path),
            "--rooms",
            str(rooms),
        ],
        check=True,
    )
    return output_path


def test_blueprint_schema(tmp_path):
    output_path = run_script(tmp_path, rooms=4)
    blueprint = yaml.safe_load(output_path.read_text(encoding="utf-8"))

    assert "metadata" in blueprint
    assert "rooms" in blueprint and len(blueprint["rooms"]) == 4
    assert "items" in blueprint and len(blueprint["items"]) == 4
    assert "characters" in blueprint and len(blueprint["characters"]) == 4

    room_ids = {room["id"] for room in blueprint["rooms"]}
    assert all(room_id.startswith("room-") for room_id in room_ids)
    for room in blueprint["rooms"]:
        assert {"id", "title", "vedabase_ref", "neighbors", "lore"}.issubset(room.keys())
        neighbors = set(room["neighbors"])
        assert neighbors.issubset(room_ids)

    for item in blueprint["items"]:
        assert item["room_id"] in room_ids
        assert item["source"] == "vedabase"

    for npc in blueprint["characters"]:
        assert npc["room_id"] in room_ids
        assert npc["id"].startswith("npc-")
        assert npc["dialogue"]

    concept = blueprint.get("concept_screens", [])
    assert concept and concept[0]["id"] == "concept-vedabase"
