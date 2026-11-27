import ReciprocalMinors.Statement

/-! A six-dimensional integral counterexample. The finite certificates use
integer arithmetic and Laplace expansion, then transport the result to ℝ. -/

namespace ReciprocalMinorExample

open Matrix OMA.S_mo_235344

def aZ : Matrix (Fin 6) (Fin 6) ℤ :=
  !![1,2,0,2,2,2; 0,0,1,0,0,0; 2,1,0,2,2,2;
     2,2,0,3,4,4; 2,2,0,2,3,4; 2,2,0,2,2,3]

def bZ : Matrix (Fin 6) (Fin 6) ℤ :=
  !![1,0,2,-2,2,-2; 2,0,1,-2,2,-2; 0,1,0,0,0,0;
     -2,0,-2,3,-4,4; 2,0,2,-2,3,-4; -2,0,-2,2,-2,3]

noncomputable def aR := (Int.castRingHom ℝ).mapMatrix aZ

noncomputable def bR := (Int.castRingHom ℝ).mapMatrix bZ

theorem inverse_certificate : aR * bR = 1 := by
  have h : aZ * bZ = 1 := by decide +kernel
  exact ((Int.castRingHom ℝ).mapMatrix.map_mul aZ bZ).symm.trans
    ((congrArg _ h).trans (map_one _))

private instance (s : Finset (Fin 6)) :
    DecidablePred (fun i : Fin 6 => ∃ j : Fin 6, i ∈ s ∧ j ∉ s ∧ aZ i j ≠ 0) :=
  fun _ => inferInstance

theorem irreducible_certificate : IrreducibleSupport aR := by
  have h : ∀ s : Finset (Fin 6), s ≠ ∅ → s ≠ Finset.univ →
      ∃ i j : Fin 6, i ∈ s ∧ j ∉ s ∧ aZ i j ≠ 0 := by decide +kernel
  intro s hne hproper
  obtain ⟨i, j, hi, hj, hij⟩ := h s hne.ne_empty hproper
  refine ⟨i, hi, j, hj, ?_⟩
  change (aZ i j : ℝ) ≠ 0
  exact_mod_cast hij

def laplace : (n : ℕ) → Matrix (Fin n) (Fin n) ℤ → ℤ
  | 0, _ => 1
  | n + 1, M => ∑ j : Fin (n + 1), (-1 : ℤ) ^ (j : ℕ) * M 0 j *
      laplace n (M.submatrix Fin.succ j.succAbove)

theorem laplace_correct (n : ℕ) (M : Matrix (Fin n) (Fin n) ℤ) :
    laplace n M = M.det := by
  induction n with
  | zero => simp [laplace]
  | succ n ih => simp only [laplace, Matrix.det_succ_row_zero M, ih]

def indices (s : Finset (Fin 6)) := (List.finRange 6).filter (fun i => i ∈ s)

theorem indices_eq (s : Finset (Fin 6)) : indices s = s.sort := by
  refine List.SortedLT.eq_of_mem_iff ?_ s.sortedLT_sort ?_
  · exact (List.Pairwise.filter _ (List.sortedLT_finRange 6).pairwise).sortedLT
  · simp [indices]

def indexAt (s : Finset (Fin 6)) (i : Fin s.card) : Fin 6 :=
  (indices s)[i.val]'(by rw [indices_eq, Finset.length_sort]; exact i.isLt)

theorem indexAt_eq (s : Finset (Fin 6)) :
    indexAt s = (s.orderEmbOfFin rfl : Fin s.card → Fin 6) := by
  funext i
  simp only [indexAt, indices_eq, Finset.orderEmbOfFin_apply, Fin.getElem_fin]

def minorZ (M : Matrix (Fin 6) (Fin 6) ℤ) (s : Finset (Fin 6)) : ℤ :=
  laplace s.card (M.submatrix (indexAt s) (indexAt s))

theorem minor_cast (M : Matrix (Fin 6) (Fin 6) ℤ) (s : Finset (Fin 6)) :
    principalMinor ((Int.castRingHom ℝ).mapMatrix M) s = (minorZ M s : ℝ) := by
  rw [minorZ, indexAt_eq, laplace_correct, Int.cast_det]
  rfl

set_option maxHeartbeats 3000000 in
set_option maxRecDepth 12000 in
theorem minors_certificate : ∀ s : Finset (Fin 6), minorZ aZ s = minorZ bZ s := by
  decide +kernel

/- The dense example in Section 2 of the note. The matrices below are
107 times the rational witness and its inverse. A common scaling preserves
equality and positivity of corresponding principal minors. -/
def denseNumerator : Matrix (Fin 6) (Fin 6) ℤ :=
  !![53, 96, -32, 80, 40, 20;
     -32, 45, 92, -16, -8, -4;
     96, -28, 45, 48, 24, 12;
     20, 12, -4, 117, 112, 56;
     40, 24, -8, 20, 117, 112;
     80, 48, -16, 40, 20, 117]

def denseInvNumerator : Matrix (Fin 6) (Fin 6) ℤ :=
  !![53, -32, 96, -80, 40, -20;
     96, 45, -28, -48, 24, -12;
     -32, 92, 45, 16, -8, 4;
     -20, 4, -12, 117, -112, 56;
     40, -8, 24, -20, 117, -112;
     -80, 16, -48, 40, -20, 117]

def triangleProduct (M : Matrix (Fin 6) (Fin 6) ℤ) (i j k : Fin 6) : ℤ :=
  M i j * M j k * M k i

set_option maxHeartbeats 3000000 in
set_option maxRecDepth 12000 in
theorem dense_certificate :
    denseNumerator * denseInvNumerator = (107 ^ 2 : ℤ) • (1 : Matrix (Fin 6) (Fin 6) ℤ) ∧
    (∀ i j, denseNumerator i j ≠ 0) ∧
    (∀ s, 0 < minorZ denseNumerator s ∧ minorZ denseNumerator s = minorZ denseInvNumerator s) ∧
    triangleProduct denseNumerator 0 1 2 ≠ triangleProduct denseInvNumerator 0 1 2 ∧
    triangleProduct denseNumerator.transpose 0 3 4 ≠ triangleProduct denseInvNumerator 0 3 4 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · decide +kernel
  · intro i
    fin_cases i <;> decide +kernel
  · decide +kernel
  · decide +kernel
  · decide +kernel

theorem no_diagonal (d : Fin 6 → ℝ) (hd : ∀ i, d i ≠ 0) :
    ¬ (aR * diagonal d = diagonal d * bR ∨
        aR.transpose * diagonal d = diagonal d * bR) := by
  rintro (h | h)
  · have h01 := congrArg (fun M : Matrix (Fin 6) (Fin 6) ℝ => M 0 1) h
    simp only [mul_diagonal, diagonal_mul] at h01
    norm_num [aR, bR, aZ, bZ, Matrix.map_apply, Matrix.of_apply, Matrix.cons_val] at h01
    exact hd 1 (by linarith)
  · have h03 := congrArg (fun M : Matrix (Fin 6) (Fin 6) ℝ => M 0 3) h
    have h34 := congrArg (fun M : Matrix (Fin 6) (Fin 6) ℝ => M 3 4) h
    have h40 := congrArg (fun M : Matrix (Fin 6) (Fin 6) ℝ => M 4 0) h
    simp only [mul_diagonal, diagonal_mul] at h03 h34 h40
    change (aZ 3 0 : ℝ) * d 3 = d 0 * (bZ 0 3 : ℝ) at h03
    change (aZ 4 3 : ℝ) * d 4 = d 3 * (bZ 3 4 : ℝ) at h34
    change (aZ 0 4 : ℝ) * d 0 = d 4 * (bZ 4 0 : ℝ) at h40
    rw [show aZ 3 0 = 2 by decide, show bZ 0 3 = -2 by decide] at h03
    rw [show aZ 4 3 = 2 by decide, show bZ 3 4 = -4 by decide] at h34
    rw [show aZ 0 4 = 2 by decide, show bZ 4 0 = 2 by decide] at h40
    norm_num at h03 h34 h40
    exact hd 0 (by linarith)

end ReciprocalMinorExample

open ReciprocalMinorExample OMA.S_mo_235344 in
theorem OMA.disproof : ¬ OMA.S_mo_235344.conjecture := by
  intro claim
  have inv_eq : aR⁻¹ = bR := Matrix.inv_eq_right_inv inverse_certificate
  have minors : ∀ s, principalMinor aR s = principalMinor aR⁻¹ s := by
    intro s
    rw [inv_eq, aR, bR, minor_cast, minor_cast, minors_certificate]
  obtain ⟨d, hd, heq⟩ := claim 6 aR
    (Matrix.isUnit_det_of_right_inverse inverse_certificate) irreducible_certificate minors
  exact no_diagonal d hd (inv_eq ▸ heq)
