#!/usr/bin/env python3
"""Generate a minimal roguelike blueprint from Vedabase exports.

The script reads a verse payload (if available) and produces a YAML file
under `build/roguelike_blueprint.yaml` containing a single room, item, and
NPC.  It is intentionally simple so future iterations can expand the
structure once more datasets are wired in.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml

BLUEPRINT_FILENAME = Path("build/roguelike_blueprint.yaml")


def load_sample_verse(json_path: Optional[Path]) -> Dict[str, Any]:
    if json_path and json_path.exists():
        data = json.loads(json_path.read_text(encoding="utf-8"))
        if isinstance(data, list) and data:
            return data[0]
        if isinstance(data, dict):
            verses = data.get("verses")
            if isinstance(verses, list) and verses:
                return verses[0]
    # Fallback sample verse
    return {
        "book": "bg",
        "chapter": 1,
        "verse": 1,
        "sanskrit": "धृतराष्ट्र उवाच",
        "translation": "Dhritarashtra said: O Sanjaya, what did my sons and the sons of Pandu do?",
        "purport": "Placeholder purport for planning purposes.",
    }


def build_blueprint(verse: Dict[str, Any]) -> Dict[str, Any]:
    book = verse.get("book", "bg")
    chapter = verse.get("chapter", 1)
    verse_no = verse.get("verse", 1)
    verse_id = f"{book}-{chapter}-{verse_no}"

    return {
        "metadata": {
            "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
            "source_verse": verse_id,
        },
        "rooms": [
            {
                "id": f"room-{verse_id}",
                "title": f"Room based on {book.upper()} {chapter}.{verse_no}",
                "vedabase_ref": {
                    "book": book,
                    "chapter": chapter,
                    "verse": verse_no,
                },
                "neighbors": [],
                "lore": {
                    "sanskrit": verse.get("sanskrit", ""),
                    "translation": verse.get("translation", ""),
                    "purport": verse.get("purport", ""),
                },
            }
        ],
        "items": [
            {
                "id": f"item-{verse_id}-scroll",
                "name": f"Scroll of {book.upper()} {chapter}.{verse_no}",
                "source": "vedabase",
                "description": verse.get("translation", ""),
            }
        ],
        "characters": [
            {
                "id": "npc-narrator",
                "name": "Narrator",
                "archetype": "guide",
                "dialogue": [
                    {
                        "type": "line",
                        "text": verse.get("purport") or verse.get("translation", ""),
                    }
                ],
            }
        ],
        "concept_screens": [
            {
                "id": "concept-vedabase",
                "title": "Vedabase Reference",
                "content": (
                    f"This room draws from {book.upper()} {chapter}.{verse_no}. "
                    "Additional context will be populated once extended data is available."
                ),
            }
        ],
    }


def ensure_build_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Generate minimal roguelike blueprint")
    repo_root = Path(__file__).resolve().parents[2]
    default_json = repo_root / "dataset" / "DUMPS" / "vedabase" / "json" / "sample.json"
    parser.add_argument(
        "--vedabase-json",
        type=Path,
        default=default_json,
        help="Path to a Vedabase verse JSON file (default: %(default)s, synthetic if missing)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=BLUEPRINT_FILENAME,
        help="Output YAML path (default: %(default)s)",
    )
    args = parser.parse_args(argv)

    verse = load_sample_verse(args.vedabase_json)
    blueprint = build_blueprint(verse)
    ensure_build_dir(args.output)
    args.output.write_text(
        yaml.safe_dump(blueprint, sort_keys=False),
        encoding="utf-8",
    )
    print(f"Blueprint written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
