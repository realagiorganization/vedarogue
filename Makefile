.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash

.PHONY: help fetch verify extract info env clean distclean tree test_dataset_was_fetched \
setup hf_fetch hf_info hf_test_dataset_was_fetched
.DEFAULT_GOAL := help

# Load local configuration if present
-include .env

# Directories
DATA_DIR ?= data
RAW_DIR ?= $(DATA_DIR)/raw
EXTRACT_DIR ?= $(DATA_DIR)/external
PROCESSED_DIR ?= $(DATA_DIR)/processed

# Dataset config (override in .env or CLI)
DATASET_NAME ?= dataset
DATASET_URL ?=
DATASET_SHA256 ?=
# Allow custom filename; fallback to last path segment of URL
DATASET_FILENAME ?= $(or $(DATASET_FILE),$(notdir $(DATASET_URL)))
DATASET_ARCHIVE ?= $(RAW_DIR)/$(DATASET_FILENAME)

MAKE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR := $(MAKE_DIR)scripts

help: ## Show available targets and brief help
	@echo "Dataset Make targets:" && \
	awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z0-9_\/_-]+:.*?## / { printf "  %-18s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ''
	@echo 'Variables (override via .env or CLI):'
	@printf "  %-18s %s\n" \
	  DATASET_NAME "Name of the dataset" \
	  DATASET_URL "HTTP(S) URL to download from" \
	  DATASET_SHA256 "Optional SHA256 checksum (recommended)" \
	  DATA_DIR "Base data directory (default: data)" \
	  HF_DATASET_ID "HF dataset id (e.g. user/name)" \
	  HF_SPLITS "Comma-separated splits to export (optional)" \
	  HF_REVISION "Branch/tag/commit sha (optional)" \
	  HF_TOKEN "Auth token if needed (optional)"

$(RAW_DIR) $(EXTRACT_DIR) $(PROCESSED_DIR):
	@mkdir -p $@

.check_vars:
	@if [ -z "$(DATASET_URL)" ]; then \
	  echo "ERROR: DATASET_URL is not set. Set it in .env or pass on CLI, e.g. make fetch DATASET_URL=..."; \
	  exit 1; \
	fi
	@if [ -z "$(DATASET_FILENAME)" ] || [ "$(DATASET_FILENAME)" = "/" ]; then \
	  echo "ERROR: Could not determine DATASET_FILENAME. Set DATASET_FILENAME in .env or pass on CLI."; \
	  exit 1; \
	fi

fetch: $(RAW_DIR) .check_vars ## Download dataset to data/raw
	@"$(SCRIPTS_DIR)/download.sh" -u "$(DATASET_URL)" -o "$(DATASET_ARCHIVE)"
	@$(MAKE) verify || true
	@echo "Downloaded: $(DATASET_ARCHIVE)"

verify: .check_vars ## Verify SHA256 checksum if provided
	@"$(SCRIPTS_DIR)/checksum.sh" -f "$(DATASET_ARCHIVE)" -s "$(DATASET_SHA256)"

extract: $(EXTRACT_DIR) .check_vars ## Extract archive into data/external
	@"$(SCRIPTS_DIR)/extract.sh" -f "$(DATASET_ARCHIVE)" -d "$(EXTRACT_DIR)"
	@echo "Extracted into: $(EXTRACT_DIR)"

test_dataset_was_fetched: fetch ## Test: dataset file exists and is non-empty
	@if [ -s "$(DATASET_ARCHIVE)" ]; then \
	  echo "PASS: $(DATASET_ARCHIVE) exists and is non-empty"; \
	else \
	  echo "FAIL: $(DATASET_ARCHIVE) missing or empty"; \
	  exit 1; \
	fi

info: ## Show resolved configuration
	@"$(SCRIPTS_DIR)/print_env.sh"

env: ## Create .env from template if missing
	@if [ -f .env ]; then echo ".env already exists"; else cp .env.example .env && echo "Created .env"; fi

tree: ## Show data directory tree (requires tree, fallback to find)
	@{ command -v tree >/dev/null && tree -a -L 2 $(DATA_DIR) || (echo "tree not found; using find" && find $(DATA_DIR) -maxdepth 2 -print 2>/dev/null) ; } || true

clean: ## Remove extracted and processed data
	@rm -rf "$(EXTRACT_DIR)" "$(PROCESSED_DIR)"
	@echo "Cleaned extracted and processed data"

distclean: clean ## Remove all data including downloads
	@rm -rf "$(RAW_DIR)"
	@echo "Removed raw downloads"

# ---------------------------
# Hugging Face integration
# ---------------------------

HF_DATASET_ID ?= manojbalaji1/anveshana
HF_SPLITS ?=
HF_REVISION ?=

PY ?= python3

setup: ## Install Python dependencies for Hugging Face datasets
	@{ command -v $(PY) >/dev/null && $(PY) -m pip install -r requirements.txt; } || { echo "Python not found"; exit 1; }

hf_fetch: $(EXTRACT_DIR) ## Fetch HF dataset and export to data/external
	@HF_TOKEN="$(HF_TOKEN)" $(PY) scripts/hf_fetch.py \
	  --dataset "$(HF_DATASET_ID)" \
	  --dest "$(EXTRACT_DIR)" \
	  $(if $(HF_REVISION),--revision "$(HF_REVISION)",) \
	  $(if $(HF_SPLITS),--splits "$(HF_SPLITS)",)
	@echo "HF dataset exported to: $(EXTRACT_DIR)"

hf_info: ## Show HF-related configuration
	@echo "HF_DATASET_ID = $(HF_DATASET_ID)"
	@echo "HF_SPLITS     = $(HF_SPLITS)"
	@echo "HF_REVISION   = $(HF_REVISION)"
	@echo "HF_TOKEN set  = $(if $(HF_TOKEN),yes,no)"

hf_test_dataset_was_fetched: hf_fetch ## Test: HF files exist in extract dir
	@cnt=$$(find "$(EXTRACT_DIR)" -maxdepth 1 -type f -name "$(shell echo $(HF_DATASET_ID) | tr "/" "_")*.parquet" | wc -l | tr -d ' '); \
	if [ "$$cnt" -gt 0 ]; then \
	  echo "PASS: Found $$cnt parquet file(s) for $(HF_DATASET_ID) in $(EXTRACT_DIR)"; \
	else \
	  echo "FAIL: No parquet files for $(HF_DATASET_ID) in $(EXTRACT_DIR)"; \
	  exit 1; \
	fi
