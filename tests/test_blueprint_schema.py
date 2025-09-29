import json
import subprocess
import sys
import tempfile
from pathlib import Path
import unittest

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "build_blueprint.py"


class BlueprintSmokeTests(unittest.TestCase):
    def _run_script(self, rooms: int) -> Path:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
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
            final_output = Path(tempfile.NamedTemporaryFile(delete=False, suffix=".yaml").name)
            final_output.write_text(output_path.read_text(encoding="utf-8"), encoding="utf-8")
            return final_output

    def test_blueprint_contains_expected_sections(self):
        output_path = self._run_script(rooms=4)
        try:
            content = output_path.read_text(encoding="utf-8")
        finally:
            output_path.unlink(missing_ok=True)

        self.assertIn("metadata:", content)
        self.assertIn("rooms:", content)
        self.assertIn("items:", content)
        self.assertIn("characters:", content)
        self.assertIn("concept_screens:", content)
        self.assertIn("room-", content)
        self.assertIn("npc-", content)


if __name__ == "__main__":
    unittest.main()
