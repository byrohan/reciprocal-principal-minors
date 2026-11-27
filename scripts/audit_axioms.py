#!/usr/bin/env python3
"""Collect Lean's transitive axiom report for each published formal target."""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOW = {"propext", "Classical.choice", "Quot.sound"}
TARGETS = (
    "OMA.disproof",
    "ReciprocalMinorExample.dense_certificate",
    "ReciprocalMinorExample.laplace_correct",
    "ReciprocalFive.certificate",
    "ReciprocalFour.certificate",
    "ReciprocalFour.laplace_det",
)


def main():
    log = subprocess.check_output(["lake", "env", "lean", "verification/Axioms.lean"], cwd=ROOT, text=True)
    reports = {}
    for name in TARGETS:
        prefix = "'" + re.escape(name) + "' "
        matches = re.findall(prefix + r"(?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)", log)
        if len(matches) != 1:
            raise SystemExit(f"Missing or ambiguous axiom report for {name}:\n{log}")
        axioms = sorted(x.strip() for x in matches[0].split(",") if x.strip())
        if set(axioms) - ALLOW:
            raise SystemExit(f"Unexpected axioms for {name}: {axioms}")
        reports[name] = axioms
    output = ROOT / "verification" / "run"
    output.mkdir(parents=True, exist_ok=True)
    (output / "axioms.json").write_text(json.dumps(reports, indent=2) + "\n")
    print(log, end="")


if __name__ == "__main__":
    main()
