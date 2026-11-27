import Mathlib

/-! The real-matrix conjecture of MathOverflow question 235344 (April 2016).
A matrix is irreducible when every nonempty proper index set has an outgoing
nonzero entry. For a nonsingular diagonal D, X * D = D * Y says exactly
that D⁻¹ * X * D = Y. -/

namespace OMA.S_mo_235344

def IrreducibleSupport {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) : Prop :=
  ∀ s : Finset (Fin n), s.Nonempty → s ≠ Finset.univ →
    ∃ i ∈ s, ∃ j ∉ s, A i j ≠ 0

noncomputable def principalMinor {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (s : Finset (Fin n)) : ℝ :=
  (A.submatrix (s.orderEmbOfFin rfl) (s.orderEmbOfFin rfl)).det

def conjecture : Prop :=
    ∀ (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ), IsUnit A.det →
      IrreducibleSupport A →
      (∀ s : Finset (Fin n), principalMinor A s = principalMinor A⁻¹ s) →
      ∃ d : Fin n → ℝ, (∀ i, d i ≠ 0) ∧
        (A * Matrix.diagonal d = Matrix.diagonal d * A⁻¹ ∨
         A.transpose * Matrix.diagonal d = Matrix.diagonal d * A⁻¹)

end OMA.S_mo_235344
