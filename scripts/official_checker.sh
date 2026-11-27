#!/usr/bin/env bash
# Fetch only public checker inputs. Candidate files stay in the temporary checkout.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
packages="$(cd .lake/packages && pwd -P)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
out="$root/verification/run/checker"
mkdir -p "$out"
checker_pin=887a1c722d5f4b3857c2bb545a4df7b611c72ef3
formal_pin=9097e2f90e66d2f6244209cb1c07f7120d17ec53

checkout_pin() {
    local repo="$1" pin="$2" dest="$3" src="$4"
    shift 4
    if [[ -n "$src" ]]; then
        git clone -q --shared --no-checkout "$src" "$dest"
    else
        git init -q "$dest"
        git -C "$dest" remote add origin "$repo"
        git -C "$dest" -c protocol.version=2 fetch --quiet --depth=1 --no-tags --filter=blob:none origin "$pin"
    fi
    git -C "$dest" sparse-checkout init --cone
    git -C "$dest" sparse-checkout set "$@"
    git -C "$dest" checkout -q --detach "$pin"
    [[ "$(git -C "$dest" rev-parse HEAD)" == "$pin" ]]
}

checkout_pin https://github.com/GuillaumeBAUD-coder/open-math-agents.git "$checker_pin" "$scratch/checker" "${OMA_CHECKER_SOURCE:-}" data tools reductions statements proofs
checkout_pin https://github.com/google-deepmind/formal-conjectures.git "$formal_pin" "$scratch/formal" "${OMA_FORMAL_SOURCE:-}" FormalConjecturesUtil
python3 -B scripts/stage_checker.py "$scratch/checker"
mkdir -p "$scratch/formal/.lake"
ln -s "$packages" "$scratch/formal/.lake/packages"
export OMA_FC="$scratch/formal"
cd "$scratch/checker"
for kind in statements proofs; do
    tools/check.sh "$kind/mo-235344.lean" "$out/$kind.json"
done
python3 -I - "$out" <<'PY'
import json,sys
from pathlib import Path
root=Path(sys.argv[1])
for kind in ("statements","proofs"):
    v=json.loads((root/(kind+".json")).read_text())
    if v["verdict"] != "accepted" or not v["ok"]:
        raise SystemExit(f"Official checker rejected {kind}")
    print(f"{kind}: {v['reason']}")
    if kind == "proofs" and (v["theorem"],v["polarity"]) != ("OMA.disproof","disproof"):
        raise SystemExit("Unexpected official target")
PY
