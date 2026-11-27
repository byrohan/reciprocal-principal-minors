# Axiom audit

The public Lean project defines the conjecture as a proposition. It proves `OMA.disproof : ¬ OMA.S_mo_235344.conjecture` by constructing a matrix. No release Lean file declares a new axiom or contains an admitted proof.

After `lake build`, run `python3 scripts/audit_axioms.py`. The script invokes Lean on the actual compiled modules and requires a transitive `#print axioms` result for each declaration below. Missing reports, unexpected axioms and Lean compilation errors fail verification. The exact result is written to `verification/run/axioms.json`. [Audit entry point](../verification/Axioms.lean) · [Enforcement script](../scripts/audit_axioms.py)

| Audited declaration | Reason for inclusion |
|---|---|
| `OMA.disproof` | Real universal conjecture negated by an order-six example. |
| `ReciprocalMinorExample.dense_certificate` | Arithmetic certificate for the dense order-six example. |
| `ReciprocalMinorExample.laplace_correct` | Identifies finite cofactor expansion with Mathlib’s determinant. |
| `ReciprocalFive.certificate` | Full complex hypotheses and failed alternatives for the order-five example. |
| `ReciprocalFour.certificate` | Exact order-four Gaussian-integer certificate. |
| `ReciprocalFour.laplace_det` | Identifies the Gaussian-integer cofactor calculation with the determinant. |

The allowed set is `propext` (propositional extensionality), `Classical.choice` (classical choice) and `Quot.sound` (soundness of quotient equality). The audit rejects `sorryAx`, extra mathematical axioms and extra evaluation axioms. The proofs use kernel reduction for finite arithmetic. As with any Lean build, the compiler, kernel, pinned library artifacts and execution environment are part of the trust boundary.

## Official checker convention

The upstream catalog requires exactly one placeholder in its proposed **statement** file. The staging adapter changes the public proposition into that mandated statement and changes the disproof’s target to the negation of the statement’s *type*. Both generated files must have exactly the archived SHA-256 hashes before checking. The official statement verdict therefore reports `sorryAx`. The official disproof verdict excludes it. The checker verifies elaboration and audits the proof dependencies. Comparing the translation with MathOverflow and the journal still requires mathematical judgment. [Adapter and hashes](../scripts/stage_checker.py) · [Pinned upstream checker](https://github.com/GuillaumeBAUD-coder/open-math-agents/blob/887a1c722d5f4b3857c2bb545a4df7b611c72ef3/tools/check.sh)
