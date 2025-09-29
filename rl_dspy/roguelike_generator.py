#!/usr/bin/env python3
from __future__ import annotations

import os
import textwrap
from dataclasses import dataclass
from typing import List, Dict, Any

try:
    import dspy  # type: ignore
except Exception:  # pragma: no cover
    dspy = None


def _coalesce_translation(row: Dict[str, Any]) -> str:
    return (row.get('translation') or '').strip()


def _coalesce_verse(row: Dict[str, Any]) -> str:
    return (row.get('verse') or row.get('document') or '').strip()


def compose_context(rows: List[Dict[str, Any]]) -> str:
    parts: List[str] = []
    for r in rows:
        split = r.get('split', '')
        idx = r.get('index', '')
        verse = _coalesce_verse(r)
        trans = _coalesce_translation(r)
        block = f"[verse {split}:{idx}]\n{verse}\n"
        if trans:
            block += f"[translation]\n{trans}\n"
        parts.append(block)
    return "\n\n".join(parts)


def ensure_dspy_configured() -> bool:
    """Configure DSPy OpenAI LM if keys are present; return True if LM configured."""
    global dspy
    if dspy is None:
        return False
    api_key = os.environ.get('OPENAI_API_KEY') or os.environ.get('OPENAI_KEY')
    model = os.environ.get('OPENAI_MODEL', 'gpt-4o-mini')
    base = os.environ.get('OPENAI_BASE')
    if api_key:
        try:  # Configure OpenAI LM
            if base:
                lm = dspy.OpenAI(model=model, api_key=api_key, base_url=base)
            else:
                lm = dspy.OpenAI(model=model, api_key=api_key)
            dspy.settings.configure(lm=lm)
            return True
        except Exception:
            return False
    return False


def _heuristic_yaml(rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Deterministic offline YAML if no LM credentials are present."""
    # Compose an ASCII map 18x10 with corridors
    w, h = 18, 10
    grid = [['#' if x in (0, w-1) or y in (0, h-1) else '.' for x in range(w)] for y in range(h)]
    for x in range(2, w-2):
        grid[h//2][x] = '='
    for y in range(2, h-2):
        grid[y][w//2] = '='
    ascii_map = ["".join(row) for row in grid]

    items = []
    for i, r in enumerate(rows[:5]):
        verse = _coalesce_verse(r)
        name = verse.split()[0][:12] if verse else f"token{i}"
        items.append({
            'id': f'it{i}',
            'name': name,
            'description': f'Item inspired by verse {r.get("split","?")}:{r.get("index","?")}',
            'location': {'x': 2 + i, 'y': h//2}
        })

    dialogs = []
    for i, r in enumerate(rows[:3]):
        verse = _coalesce_verse(r)
        dialogs.append({
            'speaker': f'sage_{i}',
            'text': verse[:200],
            'triggers': ['on_enter'] if i == 0 else ['on_pickup']
        })

    desc = textwrap.shorten(" ".join(_coalesce_verse(r) for r in rows), width=280, placeholder='…')
    return {
        'level': {
            'id': 'level_1',
            'title': 'Anveshana: Selected Verses',
            'description': desc or 'Generated from selected verses',
            'map': ascii_map,
        },
        'items': items,
        'dialogs': dialogs,
        'meta': {
            'source': 'verses.json',
            'count': len(rows),
        }
    }


if dspy is not None and hasattr(dspy, 'Signature'):
    class GenerateRoguelike(dspy.Signature):  # type: ignore
        """Create a roguelike level description in YAML strictly following the schema.

        Input: A set of verses (and optional translations) marked with [verse split:index] and [translation].
        Output: A YAML document with keys: level, items, dialogs.
        Requirements:
        - level: {id, title, description, map: list of equal-length ASCII strings}
        - items: list of {id, name, description, location: {x,y}}
        - dialogs: list of {speaker, text, triggers: list}
        - No extra commentary. Output only valid YAML.
        """
        verses_text = dspy.InputField(desc="Annotated verses and translations")
        guidelines = dspy.InputField(desc="Extra constraints or style notes", default="")
        yaml = dspy.OutputField(desc="YAML with keys: level, items, dialogs")


    class RoguelikeGeneratorLM(dspy.Module):  # type: ignore
        def __init__(self):
            super().__init__()
            self.generate = dspy.Predict(GenerateRoguelike)

        def forward(self, verses_text: str, guidelines: str = "") -> str:
            out = self.generate(verses_text=verses_text, guidelines=guidelines)
            return str(out.yaml)


@dataclass
class RoguelikeGenerator:
    """Facade that uses DSPy LM if available; else deterministic fallback."""
    use_lm: bool = False

    def __post_init__(self):
        self.use_lm = ensure_dspy_configured()
        if self.use_lm and dspy is not None:
            self.lm_impl = RoguelikeGeneratorLM()  # type: ignore
        else:
            self.lm_impl = None

    def generate_yaml(self, rows: List[Dict[str, Any]], guidelines: str = "") -> str:
        if self.use_lm and self.lm_impl is not None:
            verses_text = compose_context(rows)
            return self.lm_impl(verses_text=verses_text, guidelines=guidelines)  # type: ignore
        import yaml
        data = _heuristic_yaml(rows)
        return yaml.safe_dump(data, allow_unicode=True, sort_keys=False)
