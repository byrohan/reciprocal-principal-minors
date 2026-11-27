import Mathlib

/-! Independent complex-field certificate for the five-dimensional example.
The entrywise complex conjugate and the conjugate transpose are the two
matrices occurring in the published Theorem 7 (p. 1558). -/

namespace ReciprocalFive

open Matrix
open scoped Matrix ComplexConjugate

def a : Matrix (Fin 5) (Fin 5) ℤ :=
  !![0,-1,0,0,0; 0,0,1,1,1; -1,0,0,1,1; -2,0,-2,-1,0; -2,0,-2,-2,-1]

def b : Matrix (Fin 5) (Fin 5) ℤ :=
  !![0,0,-1,1,-1; -1,0,0,0,0; 0,1,0,-1,1; 0,-2,2,-1,0; 0,2,-2,2,-1]

noncomputable def A := (Int.castRingHom ℂ).mapMatrix a
noncomputable def B := (Int.castRingHom ℂ).mapMatrix b

theorem inv_eq : A⁻¹ = B := by
  apply Matrix.inv_eq_right_inv
  have h : a * b = 1 := by decide +kernel
  exact ((Int.castRingHom ℂ).mapMatrix.map_mul a b).symm.trans
    ((congrArg _ h).trans (map_one _))

def laplace : (n : ℕ) → Matrix (Fin n) (Fin n) ℤ → ℤ
  | 0, _ => 1
  | n+1, M => ∑ j : Fin (n+1), (-1 : ℤ) ^ (j : ℕ) * M 0 j *
      laplace n (M.submatrix Fin.succ j.succAbove)

theorem laplace_det (n) (M : Matrix (Fin n) (Fin n) ℤ) : laplace n M = M.det := by
  induction n with
  | zero => simp [laplace]
  | succ n ih => simp only [laplace, Matrix.det_succ_row_zero M, ih]

def idx (s : Finset (Fin 5)) := (List.finRange 5).filter (fun i => i ∈ s)

theorem idx_sort (s : Finset (Fin 5)) : idx s = s.sort := by
  refine List.SortedLT.eq_of_mem_iff ?_ s.sortedLT_sort ?_
  · exact (List.Pairwise.filter _ (List.sortedLT_finRange 5).pairwise).sortedLT
  · simp [idx]

def atIdx (s : Finset (Fin 5)) (i : Fin s.card) :=
  (idx s)[i.val]'(by rw [idx_sort, Finset.length_sort]; exact i.isLt)

theorem idx_eq (s : Finset (Fin 5)) :
    atIdx s = (s.orderEmbOfFin rfl : Fin s.card → Fin 5) := by
  funext i
  simp only [atIdx, idx_sort, Finset.orderEmbOfFin_apply, Fin.getElem_fin]

def minorZ (M : Matrix (Fin 5) (Fin 5) ℤ) (s : Finset (Fin 5)) :=
  laplace s.card (M.submatrix (atIdx s) (atIdx s))

noncomputable def minor (M : Matrix (Fin 5) (Fin 5) ℂ) (s : Finset (Fin 5)) :=
  (M.submatrix (s.orderEmbOfFin rfl) (s.orderEmbOfFin rfl)).det

theorem cast_minor (M : Matrix (Fin 5) (Fin 5) ℤ) (s : Finset (Fin 5)) :
    minor ((Int.castRingHom ℂ).mapMatrix M) s = (minorZ M s : ℂ) := by
  rw [minorZ, idx_eq, laplace_det, Int.cast_det]
  rfl

theorem conj_A : A.map (star : ℂ → ℂ) = A := by
  ext i j
  change star ((a i j : ℤ) : ℂ) = _
  simp [A, Matrix.map_apply]

theorem conjT_A : A.conjTranspose = A.transpose := by
  ext i j
  change star ((a j i : ℤ) : ℂ) = _
  simp [A, Matrix.map_apply]

private instance (s : Finset (Fin 5)) :
    DecidablePred (fun i : Fin 5 => ∃ j : Fin 5, i ∈ s ∧ j ∉ s ∧ a i j ≠ 0) :=
  fun _ => inferInstance

set_option maxHeartbeats 3000000 in
set_option maxRecDepth 12000 in
theorem certificate :
    IsUnit A.det ∧
    (∀ s : Finset (Fin 5), s.Nonempty → s ≠ Finset.univ →
      ∃ i ∈ s, ∃ j ∉ s, A i j ≠ 0) ∧
    (∀ s, minor (A.map (star : ℂ → ℂ)) s = minor A⁻¹ s) ∧
    ¬ ∃ d : Fin 5 → ℂ, (∀ i, d i ≠ 0) ∧
      (A.map (star : ℂ → ℂ) * diagonal d = diagonal d * A⁻¹ ∨
       A.conjTranspose * diagonal d = diagonal d * A⁻¹) := by
  have hab : a * b = 1 := by decide +kernel
  have hAB : A * B = 1 := ((Int.castRingHom ℂ).mapMatrix.map_mul a b).symm.trans
    ((congrArg _ hab).trans (map_one _))
  refine ⟨Matrix.isUnit_det_of_right_inverse hAB, ?_, ?_, ?_⟩
  · have h : ∀ s : Finset (Fin 5), s ≠ ∅ → s ≠ Finset.univ →
        ∃ i j : Fin 5, i ∈ s ∧ j ∉ s ∧ a i j ≠ 0 := by
      decide +kernel
    intro s hne hp
    obtain ⟨i,j,hi,hj,hij⟩ := h s hne.ne_empty hp
    refine ⟨i,hi,j,hj,?_⟩
    change (a i j : ℂ) ≠ 0
    exact_mod_cast hij
  · have h : ∀ s, minorZ a s = minorZ b s := by decide +kernel
    intro s
    rw [conj_A, inv_eq, A, B, cast_minor, cast_minor, h]
  · rw [conj_A, conjT_A, inv_eq]
    rintro ⟨d,hd,h | h⟩
    · have e := congrArg (fun M : Matrix (Fin 5) (Fin 5) ℂ => M 0 1) h
      simp only [mul_diagonal, diagonal_mul] at e
      change (a 0 1 : ℂ) * d 1 = d 0 * (b 0 1 : ℂ) at e
      rw [show a 0 1 = -1 by decide, show b 0 1 = 0 by decide] at e
      simp [hd] at e
    · have e := congrArg (fun M : Matrix (Fin 5) (Fin 5) ℂ => M 3 4) h
      simp only [mul_diagonal, diagonal_mul] at e
      change (a 4 3 : ℂ) * d 4 = d 3 * (b 3 4 : ℂ) at e
      rw [show a 4 3 = -2 by decide, show b 3 4 = 0 by decide] at e
      norm_num [hd, mul_eq_zero] at e

end ReciprocalFive

#print axioms ReciprocalFive.certificate
