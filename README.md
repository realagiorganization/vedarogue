**Overview**
- Purpose: Fetch, verify, and extract a dataset via a simple Makefile.
- Structure: Uses `scripts/` helpers and a `.env` file for configuration.

**Quick Start**
- Copy config: `cp .env.example .env` and set `DATASET_URL` (and `DATASET_SHA256` if known).
- Download: `make fetch` (saves to `data/raw/`).
- Verify: `make verify` (skips if no checksum provided).
- Extract: `make extract` (into `data/external/`).
- Info: `make info` to print resolved variables.

**Hugging Face Dataset (Recommended for your case)**
- Install deps: `make setup` (installs `datasets`).
- Configure: in `.env`, set `HF_DATASET_ID=manojbalaji1/anveshana`.
- Auth if needed: run `huggingface-cli login` or set `HF_TOKEN` env var.
- Fetch + export to parquet: `make hf_fetch` (outputs to `data/external/`).
- Test presence: `make hf_test_dataset_was_fetched`.

**Generate LaTeX + PDF (Emacs + LaTeX in Docker)**
- Build toolchain images (first time): `make docker_build_all`
- Export JSON (small slice): `make hf_export_json HF_SPLITS='train[:10]'`
- Generate TeX: `make emacs_tex VRANGE='train:0-9' VTITLE='Selected Verses'`
- Compile PDF: `make latex_pdf` (produces `build/verses.pdf`).
- All-in-one: `make build_pdf HF_SPLITS='train[:10]' VRANGE='train:0-9' VTITLE='Selected Verses'`

Notes:
- The Emacs script reads `build/verses.json` and writes `build/verses.tex`.
- The LaTeX template uses `polyglossia` and `fontspec` with `Noto Sans Devanagari` for Sanskrit.
- This pipeline strictly uses Docker. Ensure images are present:
  - Build local multi-arch images: `make docker_build_all` (recommended)
  - Or set env vars to alternative images: `EMACS_IMAGE`, `TEX_IMAGE`, `OCR_IMAGE`, `POPPLER_IMAGE`, `PY_IMAGE`, then `make images_pull`

**DSPy Roguelike YAML**
- Purpose: Generate a roguelike screen description (level, items, dialogs) YAML from a range of verses, with optional LLM.
- CLI: `python3 scripts/dspy_generate_yaml.py --json build/verses.json --out build/roguelike.yaml --range 'train:0-9'`.
- Make targets:
  - `dspy_yaml`: runs the generator (set `VRANGE` and optional `GUIDELINES`).
  - `dspy_test`: runs pytest for schema and content checks.
  - `dspy_notebook`: executes a self-improvement Jupyter notebook that regenerates YAML with stricter guidelines.
- Notebook: `notebooks/roguelike_self_improve.ipynb` creates `build/roguelike.baseline.yaml` and `build/roguelike.improved.yaml`.

**LLM Keys (for DSPy)**
- `OPENAI_API_KEY`: API key to enable DSPy LM calls (optional; CI uses deterministic fallback).
- `OPENAI_MODEL`: model id, e.g., `gpt-4o-mini` (default).
- `OPENAI_BASE`: custom API base URL (optional).
- Without keys, the generator uses a deterministic offline heuristic and tests still pass.

**Config Variables**
- DATASET_NAME: label for the dataset (optional).
- DATASET_URL: HTTP(S) URL to the dataset file (required for `fetch`).
- DATASET_SHA256: expected checksum (optional but recommended).
- DATA_DIR: base folder for data (default: `data`).
- DATASET_FILENAME: override inferred filename from URL.

**Targets**
- `help`: Lists available targets and variables.
- `fetch`: Downloads to `data/raw/` using `curl` or `wget` with resume.
- `verify`: Validates SHA256 if provided (supports `sha256sum` or `shasum`).
- `extract`: Extracts archives (`.tar.gz`, `.tgz`, `.tar.xz`, `.tar.bz2`, `.zip`, `.gz`).
- `env`: Creates `.env` from template if missing.
- `tree`: Shows `data/` tree if `tree` exists; falls back to `find`.
- `clean`: Removes extracted and processed data.
- `distclean`: Also removes raw downloads.
 - `setup`: Installs Python deps for Hugging Face integration.
 - `hf_fetch`: Downloads and exports Hugging Face dataset splits to parquet.
- `hf_info`: Shows HF-related configuration.
- `hf_test_dataset_was_fetched`: Verifies parquet exports exist.
 - `hf_export_json`: Exports selected rows to `build/verses.json` for Emacs.
 - `emacs_tex`: Runs Emacs (batch) to generate `build/verses.tex`.
 - `latex_pdf`: Builds `build/verses.pdf` using LaTeX in Docker.
 - `build_pdf`: Convenience: export JSON, generate TeX, compile PDF.
 - `ocr_pdf`: OCR the PDF to add a searchable text layer.
 - `pdf_text`: Extract text from the OCRed PDF to a `.txt` file.
 - `ocr_and_test`: Runs OCR+extraction and validates against expected verses.
 - `ci`: CI-friendly target that runs the full pipeline (dataset → TeX → PDF → OCR → validation) and DSPy YAML + tests.
 - `docker_build_all`: Build local toolchain Docker images (Emacs, TeX, OCR, Poppler).
 - `check_images`: Verify required images are present locally (fails otherwise).
 - `images_pull`: Pull configured images from registries.
 - `dspy_yaml`: Generate roguelike YAML from verses.
 - `dspy_test`: Run pytest for DSPy program.
 - `dspy_notebook`: Execute self-improvement Jupyter notebook.

**Examples**
- One-off fetch via CLI without `.env`:
  - `make fetch DATASET_URL=https://example.com/archive.zip`
- Fetch with checksum verification:
  - `make fetch DATASET_URL=https://... DATASET_SHA256=0123abcd...`
- Override filename if URL is not descriptive:
  - `make fetch DATASET_URL='https://.../download?id=123' DATASET_FILENAME=mydata.zip`
- Hugging Face dataset export (all splits):
 - `make setup && make hf_fetch HF_DATASET_ID=manojbalaji1/anveshana`
- Specific splits with revision and token:
  - `make hf_fetch HF_DATASET_ID=manojbalaji1/anveshana HF_SPLITS=train,test HF_REVISION=main HF_TOKEN=xxxx`
 - Build images, export JSON and build PDF for 10 rows:
   - `make docker_build_all && make build_pdf HF_SPLITS='train[:10]' VRANGE='train:0-9'`
 - OCR and validate the PDF content against the exported JSON:
   - `make ocr_and_test`
 - Generate roguelike YAML for 10 rows:
   - `make hf_export_json HF_SPLITS='train[:10]' && make dspy_yaml VRANGE='train:0-9'`
 - Run tests and self-improvement notebook:
   - `make dspy_test && make dspy_notebook`
 - Full CI pipeline locally (after building images):
   - `make docker_build_all && make ci`

**Notes**
- Requires either `curl` or `wget` to download, and `unzip` for zip archives.
- `verify` is best-effort; provide `DATASET_SHA256` for integrity checking.
