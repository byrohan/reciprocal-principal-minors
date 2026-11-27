import Mathlib

/-! Gaussian-integer certificate for the smallest complex witness.
The displayed numerators are five times the matrix and inverse. Common
scaling multiplies corresponding order-k minors by the same factor 5^k. -/

namespace ReciprocalFour

open Matrix

def g (r i : ℤ) : GaussianInt := ⟨r,i⟩

def a : Matrix (Fin 4) (Fin 4) GaussianInt :=
  !![0, (-5), 0, 0;
     g (-2) (-1), 0, g (1) (3), g (-2) (4);
     g (-2) (4), 0, g (1) (-2), g (-2) (4);
     g (1) (3), 0, g (-3) (1), g (1) (-2)]

def b : Matrix (Fin 4) (Fin 4) GaussianInt :=
  !![0, g (-2) (1), g (1) (-3), g (-2) (-4);
     (-5), 0, 0, 0;
     0, g (-2) (-4), g (1) (2), g (-2) (-4);
     0, g (1) (-3), g (-3) (-1), g (1) (2)]

def laplace : (n : ℕ) → Matrix (Fin n) (Fin n) GaussianInt → GaussianInt
  | 0, _ => 1
  | n+1, M => ∑ j : Fin (n+1), (-1 : GaussianInt) ^ (j : ℕ) * M 0 j *
      laplace n (M.submatrix Fin.succ j.succAbove)

theorem laplace_det (n) (M : Matrix (Fin n) (Fin n) GaussianInt) : laplace n M = M.det := by
  induction n with
  | zero => simp [laplace]
  | succ n ih => simp only [laplace, Matrix.det_succ_row_zero M, ih]

def idx (s : Finset (Fin 4)) := (List.finRange 4).filter (fun i => i ∈ s)

theorem idx_sort (s : Finset (Fin 4)) : idx s = s.sort := by
  refine List.SortedLT.eq_of_mem_iff ?_ s.sortedLT_sort ?_
  · exact (List.Pairwise.filter _ (List.sortedLT_finRange 4).pairwise).sortedLT
  · simp [idx]

def atIdx (s : Finset (Fin 4)) (i : Fin s.card) :=
  (idx s)[i.val]'(by rw [idx_sort, Finset.length_sort]; exact i.isLt)

theorem idx_eq (s : Finset (Fin 4)) :
    atIdx s = (s.orderEmbOfFin rfl : Fin s.card → Fin 4) := by
  funext i
  simp only [atIdx, idx_sort, Finset.orderEmbOfFin_apply, Fin.getElem_fin]

def minorZ (M : Matrix (Fin 4) (Fin 4) GaussianInt) (s : Finset (Fin 4)) :=
  laplace s.card (M.submatrix (atIdx s) (atIdx s))


def circuit (M : Matrix (Fin 4) (Fin 4) GaussianInt) :=
  M 0 2 * M 2 3 * M 3 1 * M 1 0

set_option maxHeartbeats 1500000 in
set_option maxRecDepth 10000 in
theorem certificate :
    a * b = (25 : GaussianInt) • (1 : Matrix (Fin 4) (Fin 4) GaussianInt) ∧
    (∀ s, minorZ (a.map star) s = minorZ b s) ∧
    a 0 1 * a 1 2 * a 2 3 * a 3 0 ≠ 0 ∧
    (a.map star) 1 2 ≠ 0 ∧ b 1 2 = 0 ∧
    circuit a.conjTranspose ≠ circuit b := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> decide +kernel

end ReciprocalFour

#print axioms ReciprocalFour.certificate
#print axioms ReciprocalFour.laplace_det
