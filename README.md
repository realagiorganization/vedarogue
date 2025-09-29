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

**Notes**
- Requires either `curl` or `wget` to download, and `unzip` for zip archives.
- `verify` is best-effort; provide `DATASET_SHA256` for integrity checking.
