#!/usr/bin/env bash
set -euo pipefail

# Print resolved env vars for Makefile dataset config
printf "%-18s : %s\n" DATASET_NAME "${DATASET_NAME:-}" || true
printf "%-18s : %s\n" DATASET_URL "${DATASET_URL:-}" || true
printf "%-18s : %s\n" DATASET_SHA256 "${DATASET_SHA256:-}" || true
printf "%-18s : %s\n" DATA_DIR "${DATA_DIR:-data}" || true
printf "%-18s : %s\n" RAW_DIR "${RAW_DIR:-data/raw}" || true
printf "%-18s : %s\n" EXTRACT_DIR "${EXTRACT_DIR:-data/external}" || true
printf "%-18s : %s\n" PROCESSED_DIR "${PROCESSED_DIR:-data/processed}" || true

