# Reproduction

Run commands from the repository root. The default Lake target builds all four Lean source modules. The full replay uses a temporary directory for the upstream checker and its official problem environment.

## First run

Start with a clone or an extracted GitHub source ZIP and change into the directory containing `lean-toolchain`. Install Git, [Elan](https://github.com/leanprover/elan), Python 3.9+, Bash, Ruby with its `matrix` and `json` libraries, and GNU Coreutils’ `timeout`. On macOS, a Coreutils installation may name this executable `gtimeout`. Put the Coreutils `gnubin` directory on your shell’s PATH so that the upstream checker can call it as `timeout`. Confirm with `command -v timeout`. Check that `lake --version` selects the repository toolchain and that `ruby -rmatrix -rjson -e 'puts RUBY_VERSION'` prints your Ruby version. Python uses its standard library. Lean and Mathlib downloads can take several gigabytes on a new machine.

```sh
lake exe cache get
./scripts/verify.sh
```

Success ends with `Verification receipt matches this release.` The independently generated `verification/run/receipt.json` then matches the published `verification/release.json`. On macOS or Linux, `cmp verification/run/receipt.json verification/release.json` provides a separate byte-level comparison and exits silently on success.

The lockfile pins Mathlib and its eight transitive packages. The verifier checks each Git revision, tracked source cleanliness, the active Lean version and the official checker target. Expected wall time depends primarily on downloading the Mathlib cache. The numerical scripts use integers, rationals and exact Gaussian arithmetic.

| Component | Version or commit |
|---|---|
| Lean | 4.33.1 |
| Mathlib | `0df444a360eaa60ab8c11dca51a86af692955474` |
| Official Open Math Agents checker | `887a1c722d5f4b3857c2bb545a4df7b611c72ef3` |
| Upstream formal-conjectures | `9097e2f90e66d2f6244209cb1c07f7120d17ec53` |

[Lean toolchain](../lean-toolchain) · [Complete Lake dependency lock](../lake-manifest.json) · [Checker source at the tested revision](https://github.com/GuillaumeBAUD-coder/open-math-agents/blob/887a1c722d5f4b3857c2bb545a4df7b611c72ef3/tools/check.sh) · [Formal Conjectures revision](https://github.com/google-deepmind/formal-conjectures/tree/9097e2f90e66d2f6244209cb1c07f7120d17ec53)

## Existing cache or offline use

In a fresh checkout with the pinned Lean toolchain already installed, set `MATHLIB_PACKAGES` to an existing Lake packages directory containing the locked source revisions and their compiled artifacts. Optionally set `OMA_CHECKER_SOURCE` and `OMA_FORMAL_SOURCE` to local Git clones containing the published pins. The checker works in temporary clones. Both source overrides together avoid fetching the checker or the formal-conjectures repository.

```sh
mkdir -p .lake
ln -s "$MATHLIB_PACKAGES" .lake/packages
./scripts/verify.sh
```

The verifier rebuilds this project’s own Lean modules in the checkout. The package cache must match the Lean version, operating system and architecture. The GitHub workflow uses the first-run commands on Ubuntu.

## Individual steps

| Command | Result |
|---|---|
| `lake build` | Compiles every release Lean module. |
| `python3 scripts/audit_axioms.py` | After the build, collects and checks six transitive axiom reports. |
| `python3 -B scripts/exact_real.py verification/run/python` | Uses only Python to reconstruct the four real examples, including the README pair, and write the labeled minor table. |
| `python3 -B scripts/exact_complex.py verification/run/python` | Uses only Python to check the four-dimensional complex example. |
| `python3 -B scripts/check_exact.py` | Runs the three Python reproductions, the bounded four-dimensional regression, and two independent Ruby checks. Compares all seven numerical records. |
| `bash scripts/official_checker.sh` | Stages the real target and disproof, checks their archived SHA-256 hashes, and runs the pinned official checker. |
| `./scripts/build_paper.sh` | Prints the editable HTML to the paper PDF using a local Chromium or Chrome executable. Set `CHROME_BIN` when it is outside PATH. |

The expected arithmetic records are deterministic. The checker’s temporary submission filename and the PDF’s print timestamp, font selection and browser metadata can differ across runs. [Expected records](../verification/expected) · [Public release verification](verification.md)
