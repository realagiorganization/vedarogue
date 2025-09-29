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
from typing import Any, Dict, Iterable, List, Optional, Set, Tuple

import yaml

BLUEPRINT_FILENAME = Path("build/roguelike_blueprint.yaml")


def load_verses(json_path: Optional[Path], limit: int) -> List[Dict[str, Any]]:
    verses: List[Dict[str, Any]] = []
    if json_path and json_path.exists():
        payload = json.loads(json_path.read_text(encoding="utf-8"))
        verses.extend(list(_extract_verses(payload)))
    if not verses:
        verses.append(
            {
                "book": "bg",
                "chapter": 1,
                "verse": 1,
                "sanskrit": "धृतराष्ट्र उवाच",
                "translation": "Dhritarashtra said: O Sanjaya, what did my sons and the sons of Pandu do?",
                "purport": "Placeholder purport for planning purposes.",
            }
        )
    return verses[: max(1, limit)]


def _extract_verses(payload: Any, seen: Optional[Set[int]] = None) -> Iterable[Dict[str, Any]]:
    if seen is None:
        seen = set()
    obj_id = id(payload)
    if obj_id in seen:
        return
    seen.add(obj_id)

    if isinstance(payload, dict):
        if {"translation", "sanskrit"}.issubset(payload.keys()) and payload.get("verse") is not None:
            yield payload
        for key in ("verses", "data", "items", "results", "pages"):
            value = payload.get(key)
            if isinstance(value, list):
                for item in value:
                    yield from _extract_verses(item, seen)
        for value in payload.values():
            if isinstance(value, dict):
                yield from _extract_verses(value, seen)
    elif isinstance(payload, list):
        for item in payload:
            yield from _extract_verses(item, seen)


def build_blueprint(verses: List[Dict[str, Any]]) -> Dict[str, Any]:
    rooms = []
    items = []
    characters = []
    for index, verse in enumerate(verses):
        book = verse.get("book", "bg")
        chapter = verse.get("chapter", 1)
        verse_no = verse.get("verse", index + 1)
        room_id = f"room-{book}-{chapter}-{verse_no}"
        room = {
            "id": room_id,
            "title": f"Room based on {book.upper()} {chapter}.{verse_no}",
            "vedabase_ref": {"book": book, "chapter": chapter, "verse": verse_no},
            "neighbors": [],
            "lore": {
                "sanskrit": verse.get("sanskrit", ""),
                "translation": verse.get("translation", ""),
                "purport": verse.get("purport", ""),
            },
        }
        rooms.append(room)
        items.append(
            {
                "id": f"item-{book}-{chapter}-{verse_no}",
                "name": f"Scroll of {book.upper()} {chapter}.{verse_no}",
                "source": "vedabase",
                "description": verse.get("translation", ""),
                "room_id": room_id,
            }
        )
        characters.append(
            {
                "id": f"npc-{book}-{chapter}-{verse_no}",
                "name": f"Guide {index + 1}",
                "archetype": "guide",
                "room_id": room_id,
                "dialogue": [
                    {
                        "type": "line",
                        "text": verse.get("purport") or verse.get("translation", ""),
                    }
                ],
            }
        )

    # Link rooms linearly for now
    for current, nxt in _pairwise(rooms):
        current["neighbors"].append(nxt["id"])
        nxt["neighbors"].append(current["id"])

    metadata = {
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "source_verses": [room["vedabase_ref"] for room in rooms],
    }

    blueprint = {
        "metadata": metadata,
        "rooms": rooms,
        "items": items,
        "characters": characters,
        "concept_screens": [
            {
                "id": "concept-vedabase",
                "title": "Vedabase Reference",
                "content": (
                    "Each room is generated from Vedabase verses. "
                    "As the pipeline matures, this screen will include underword translations and cross references."
                ),
            }
        ],
    }
    return blueprint


def _pairwise(sequence: List[Dict[str, Any]]) -> Iterable[Tuple[Dict[str, Any], Dict[str, Any]]]:
    for index in range(len(sequence) - 1):
        yield sequence[index], sequence[index + 1]


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
    parser.add_argument(
        "--rooms",
        type=int,
        default=3,
        help="Number of rooms (and verses) to include (default: %(default)s)",
    )
    args = parser.parse_args(argv)

    verses = load_verses(args.vedabase_json, args.rooms)
    blueprint = build_blueprint(verses)
    ensure_build_dir(args.output)
    args.output.write_text(
        yaml.safe_dump(blueprint, sort_keys=False),
        encoding="utf-8",
    )
    print(f"Blueprint written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
