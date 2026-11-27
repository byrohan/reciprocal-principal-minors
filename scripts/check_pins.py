#!/usr/bin/env python3
"""Reject an incorrect Lean executable, substituted package revision or changed dependency source."""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "lake-manifest.json").read_text())
version = (ROOT / "lean-toolchain").read_text().strip().split(":v")[1]
lean = subprocess.check_output(["lake", "env", "lean", "--version"], cwd=ROOT, text=True).strip()
if not re.search(r"version " + re.escape(version) + r"[,)]", lean):
    raise SystemExit(f"Expected Lean {version}, got {lean}")
for package in manifest["packages"]:
    path = ROOT / manifest["packagesDir"] / package["name"]
    git = ["git", "-C", str(path)]
    sha = subprocess.check_output(git + ["rev-parse", "HEAD"], text=True).strip()
    if sha != package["rev"]:
        raise SystemExit(f"Wrong revision of {package['name']}: {sha}")
    subprocess.run(git + ["diff", "--quiet", "HEAD", "--"], check=True)
print(lean)
print(f"Verified {len(manifest['packages'])} package revisions and their tracked sources.")
