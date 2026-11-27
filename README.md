# Reciprocal principal minors and the limits of diagonal similarity

An invertible matrix and its inverse can agree on the determinant of **every corresponding principal submatrix**, even though no rescaling of the coordinates turns one matrix, or its transpose, into the other. This disproves Sebastian Schlecht’s 2016 real-matrix conjecture. The examples also disprove **Theorem 7 of the published Schlecht–Habets paper**, which makes a related assertion for complex matrices. [Original question](https://mathoverflow.net/q/235344) · [IEEE article, p. 1558](https://doi.org/10.1109/TSP.2016.2637323)

[Read the paper (PDF)](paper/manuscript.pdf) · [Editable manuscript](paper/manuscript.html) · [Verification report](docs/verification.md) · [Historical assessment](docs/history.md)

## A counterexample you can check by hand

Here is the five-dimensional integer matrix and its inverse, with rows and columns numbered from zero.

```text
       0 −1  0  0  0                 0  0 −1  1 −1
       0  0  1  1  1                −1  0  0  0  0
 A =  −1  0  0  1  1          B =   0  1  0 −1  1
      −2  0 −2 −1  0                 0 −2  2 −1  0
      −2  0 −2 −2 −1                 0  2 −2  2 −1
```

Multiplication gives $AB=I$. The directed cycle 0 → 1 → 2 → 4 → 3 → 0 proves irreducibility. Swapping coordinates 0 and 1 and conjugating by the diagonal signs $(1,1,-1,1,-1)$ carries $A$ to $B$. A selected set of coordinates containing both swapped indices or neither is unchanged. If the set contains only 0, the selected row 0 of $A$ is zero. If it contains only 1, the selected column 1 is zero. Hence all 32 labeled minors agree.

An invertible diagonal change of units preserves the positions of zeros. At position (0,1), the entries of $A$ and $B$ are −1 and 0. At (3,4), the entries of the transpose of $A$ and of $B$ are −2 and 0. This excludes both alternatives, even when the changes of units are complex.

## Scope and significance

The manuscript proves that five is the smallest real order and four is the smallest order for the paper’s complex conjugate-inverse assertion. Dense rational examples with strictly positive principal minors show that missing connections and zero minors are unnecessary. The two minimality bounds, the infinite construction and the alternative feedback-network argument have ordinary mathematical proofs. Lean checks the real disproof and a five-dimensional witness under the published complex hypotheses. [Claim-by-claim verification](docs/verification.md)

The published Appendix B drops a rank condition, applies induction to principal deletions that can cease to be inverse pairs, and equates two different mixed minors. Explicit unitary feedback designs retain their losslessness guarantee. The literature review located no earlier disproof of the precise inverse-pair claim. Historical priority and peer review remain open. [Source comparison and prior art](docs/history.md)

## Reproduce

With Git, Elan, Python 3.9 or later, Ruby with `matrix` and `json`, Bash and GNU `timeout` on the path, run from the repository root:

```sh
lake exe cache get
./scripts/verify.sh
```

The first command obtains the locked Mathlib artifacts. The second builds the Lean project, checks each theorem’s axioms, runs the exact scripts and replays the pinned Left to Solve checker locally. It writes fresh results under `verification/run/`. To run just the arithmetic, use `python3 -B scripts/check_exact.py`. None of these commands requires a hosting account or submits a proof. [Instructions for cached/offline use, macOS and PDF regeneration](docs/reproduction.md)

## Attribution and reuse

OpenAI Codex carried out the mathematical search, construction, formalization and writing under human direction. Verification includes separate algorithms and a proof-assistant kernel check. The project has received no independent human peer review. [Discovery process](docs/provenance.md) · [Axiom audit](docs/axioms.md) · [Citation metadata](CITATION.cff) · [Licenses](LICENSE)
