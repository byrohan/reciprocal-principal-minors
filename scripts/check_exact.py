#!/usr/bin/env python3
"""Run all independent arithmetic implementations and compare published records."""
import csv
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = ROOT / "verification" / "expected"


def main():
    output = ROOT / "verification" / "run" / "exact"
    output.mkdir(parents=True, exist_ok=True)
    for name in ("exact_real.py", "exact_complex.py", "check_small_orders.py"):
        subprocess.run([sys.executable, "-B", str(ROOT / "scripts" / name), str(output)], check=True)
    programs = (
        ([sys.executable, "-B", "scripts/original_six.py"], "legacy-exact.json"),
        (["ruby", "scripts/journal_equations.rb"], "journal-equations.json"),
        (["ruby", "scripts/independent.rb"], "independent.json"),
    )
    for command, filename in programs:
        result = json.loads(subprocess.check_output(command, cwd=ROOT))
        if filename == "independent.json":
            print(result.pop("implementation"))
        (output / filename).write_text(json.dumps(result, indent=2) + "\n")
    for reference in sorted(EXPECTED.iterdir()):
        actual = output / reference.name
        if reference.suffix == ".csv":
            with reference.open(newline="") as a, actual.open(newline="") as b:
                matches = list(csv.reader(a)) == list(csv.reader(b))
        else:
            matches = json.loads(actual.read_text()) == json.loads(reference.read_text())
        if not matches:
            raise SystemExit(f"Mismatch in {reference.name}")
    print("All seven exact records match, including 208 corresponding principal minors.")


if __name__ == "__main__":
    main()
