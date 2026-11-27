#!/usr/bin/env python3
"""Adapt the public Prop definition to the pinned checker's submission syntax."""
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PINS = {
    "statements": "6f79f1b21e897c8af084f00c5baf9a0d5f52735714fc496f2b8eb740942fbc84",
    "proofs": "28a77087309a32c9dab90070fa8784e137f087e56f4446d0ec2a35896d1722bc",
}


def write(target, kind, source):
    data = source.encode()
    if hashlib.sha256(data).hexdigest() != PINS[kind]:
        raise SystemExit(f"The generated {kind} file differs from the independently audited original.")
    path = target / kind / "mo-235344.lean"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


if __name__ == "__main__":
    target = Path(sys.argv[1])
    statement = (ROOT / "ReciprocalMinors/Statement.lean").read_text()
    statement = statement.replace("def conjecture : Prop :=", "theorem main :")
    statement = statement.replace(" d * A⁻¹)\n", " d * A⁻¹) := by\n  sorry\n")
    proof = (ROOT / "ReciprocalMinors/Six.lean").read_text()
    proof = proof.replace("import ReciprocalMinors.Statement", "import OMAStatements.S_mo_235344")
    proof = proof.replace("¬ OMA.S_mo_235344.conjecture", "¬ (type_of% @OMA.S_mo_235344.main)")
    write(target, "statements", statement)
    write(target, "proofs", proof)
