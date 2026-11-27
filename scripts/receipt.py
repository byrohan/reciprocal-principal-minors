#!/usr/bin/env python3
"""Bind the verification results to the checked sources with a portable receipt."""
import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / "verification" / "run"


def read(path):
    return json.loads(path.read_text())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record", action="store_true", help="write the reference receipt from a completed run")
    args = parser.parse_args()
    parts = ["ReciprocalMinors", "scripts", "verification/expected"]
    files = [ROOT / x for x in ("lakefile.toml", "lake-manifest.json", "lean-toolchain",
                                "ReciprocalMinors.lean", "verification/Axioms.lean",
                                "paper/manuscript.html", ".github/workflows/verify.yml")]
    for folder in parts:
        files.extend(p for p in (ROOT / folder).iterdir() if p.is_file())
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sorted(files)}
    proof = read(RUN / "checker" / "proofs.json")
    stmt = read(RUN / "checker" / "statements.json")
    with (RUN / "exact" / "all-minors.csv").open(newline="") as f:
        real_minor_count = sum(1 for _ in csv.DictReader(f))
    complex_minor_count = len(read(RUN / "exact" / "four-complex.json")["minors_numerators"])
    receipt = {
        "lean_toolchain": (ROOT / "lean-toolchain").read_text().strip(),
        "package_revisions": {p["name"]: p["rev"] for p in read(ROOT / "lake-manifest.json")["packages"]},
        "axioms": read(RUN / "axioms.json"),
        "official_checker": {
            "statement": stmt["verdict"], "statement_requires_semantic_review": True,
            "proof": {k: proof[k] for k in ("verdict", "polarity", "theorem", "reason", "log")},
        },
        "labeled_minor_equalities": {"real": real_minor_count, "complex": complex_minor_count},
        "bounded_regression": read(RUN / "exact" / "small-order-search.json"),
        "source_sha256": hashes,
    }
    result = json.dumps(receipt, indent=2, sort_keys=True) + "\n"
    (RUN / "receipt.json").write_text(result)
    reference = ROOT / "verification/release.json"
    if args.record:
        reference.write_text(result)
    if read(reference) != receipt:
        raise SystemExit("Fresh receipt differs from the recorded release. Inspect verification/run/receipt.json.")
    print("Verification receipt matches this release.")


if __name__ == "__main__":
    main()
