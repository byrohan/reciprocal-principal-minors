#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -B scripts/check_pins.py
lake build
python3 -B scripts/audit_axioms.py
python3 -B scripts/check_exact.py
bash scripts/official_checker.sh
python3 -B scripts/receipt.py
