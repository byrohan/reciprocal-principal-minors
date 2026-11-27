#!/usr/bin/env python3
"""Reproduce the counterexample with exact arithmetic and the Leibniz determinant."""
from fractions import Fraction
from itertools import combinations, permutations
from math import prod
import json

A = [
    [1, 2, 0, 2, 2, 2],
    [0, 0, 1, 0, 0, 0],
    [2, 1, 0, 2, 2, 2],
    [2, 2, 0, 3, 4, 4],
    [2, 2, 0, 2, 3, 4],
    [2, 2, 0, 2, 2, 3],
]
B = [
    [1, 0, 2, -2, 2, -2],
    [2, 0, 1, -2, 2, -2],
    [0, 1, 0, 0, 0, 0],
    [-2, 0, -2, 3, -4, 4],
    [2, 0, 2, -2, 3, -4],
    [-2, 0, -2, 2, -2, 3],
]
N = range(6)
IDENTITY = [[int(i == j) for j in N] for i in N]
H = [[0 for j in N] for i in N]
for i, j in [(0, 1), (1, 2), (2, 0)]:
    H[i][j], H[j][i] = 1, -1
for i, j in [(0, 3), (3, 4), (4, 5), (5, 0)]:
    H[i][j] = 1


def require(condition, description):
    if not condition:
        raise ValueError(description)


def multiply(left, right):
    return [[sum(x*y for x, y in zip(row, col)) for col in zip(*right)] for row in left]


def determinant(matrix):
    total = 0
    for perm in permutations(range(len(matrix))):
        inversions = sum(a > b for a, b in combinations(perm, 2))
        total += (-1)**inversions * prod(matrix[i][j] for i, j in enumerate(perm))
    return total


def principal(matrix, indices):
    return [[matrix[i][j] for j in indices] for i in indices]


def shifted(t):
    return [[IDENTITY[i][j] + t*H[i][j] for j in N] for i in N]


def cayley(t):
    # Solve (I - tH) X = I + tH by exact row operations.
    augmented = [list(map(Fraction, l + r)) for l, r in zip(shifted(-t), shifted(t))]
    for j in N:
        pivot = next(i for i in range(j, 6) if augmented[i][j])
        augmented[j], augmented[pivot] = augmented[pivot], augmented[j]
        divisor = augmented[j][j]
        augmented[j] = [value/divisor for value in augmented[j]]
        for i in N:
            if i != j:
                scale = augmented[i][j]
                augmented[i] = [x - scale*y for x, y in zip(augmented[i], augmented[j])]
    return [row[6:] for row in augmented]


def cycle_product(matrix, vertices):
    return prod(matrix[i][j] for i, j in zip(vertices, vertices[1:] + vertices[:1]))


def check():
    require(multiply(A, B) == multiply(B, A) == IDENTITY, "two-sided inverse")
    require(determinant(A) == 1, "unimodular")
    require(cycle_product(A, list(N)) != 0, "directed Hamilton cycle")
    require(A[0][1] != 0 and B[0][1] == 0, "diagonal similarity obstruction")
    triangle = [0, 3, 4]
    products = [cycle_product(m, triangle) for m in (list(zip(*A)), B)]
    require(products == [8, 16], "transpose similarity obstruction")
    swap = [0, 2, 1, 3, 4, 5]
    signs = [1, 1, 1, -1, 1, -1]
    require(all(B[i][j] == signs[i]*A[swap[i]][swap[j]]*signs[j]
                for i in N for j in N), "signed permutation identity")
    coefficients = []
    for k in range(7):
        coefficient = 0
        for subset in combinations(N, k):
            require(determinant(principal(A, subset)) == determinant(principal(B, subset)),
                    f"corresponding principal minor at {subset}")
            minor_h = determinant(principal(H, subset))
            require(k % 2 == 0 or minor_h == 0, f"odd minor of H at {subset}")
            coefficient += minor_h
        coefficients.append(coefficient)
    require(cayley(1) == A and cayley(-1) == B, "Cayley reconstruction")
    dense = cayley(Fraction(1, 2))
    require(all(value for row in dense for value in row), "dense rational witness")
    dense_inverse = cayley(Fraction(-1, 2))
    dense_minors = []
    for k in range(7):
        for subset in combinations(N, k):
            value = determinant(principal(dense, subset))
            require(value == determinant(principal(dense_inverse, subset)),
                    f"dense inverse pair at {subset}")
            dense_minors.append(value)
    require(min(dense_minors) == Fraction(43, 107), "positive principal minors")
    distinct = sorted(set(dense_minors))
    require([107*x for x in distinct] == [43, 45, 51, 53, 107, 117],
            "distinct dense principal minors")
    require(multiply(dense, dense_inverse) == IDENTITY, "dense inverse")
    require(cycle_product(dense, [0, 1, 2]) != cycle_product(dense_inverse, [0, 1, 2])
            and cycle_product(list(zip(*dense)), triangle) != cycle_product(dense_inverse, triangle),
            "both dense similarity obstructions")
    for i, j in combinations((3, 4, 5), 2):
        require(cycle_product(list(zip(*A)), [0, i, j]) == 8
                and cycle_product(B, [0, i, j]) == 16, "obstruction after deletion")
    reduced_indices = [0, 1, 2, 4, 5]
    deleted = multiply(principal(A, reduced_indices), principal(B, reduced_indices))
    require(deleted[0][0] == 5, "deletion does not preserve inverses")
    return {
        "dimension": 6, "determinant": determinant(A), "two_sided_inverse": True,
        "principal_subsets_checked": 2**len(N), "directed_Hamilton_cycle": [*N, 0],
        "A01_B01": [A[0][1], B[0][1]], "cycle_products_AT_B": products,
        "odd_principal_minors_of_H_checked": 32, "det_I_plus_tH_low_to_high": coefficients,
        "nonzero_entries_at_t_one_half": sum(bool(x) for row in dense for x in row),
        "dense_principal_minors": [str(x) for x in distinct],
        "deleted_product_00": deleted[0][0],
    }


if __name__ == "__main__":
    print(json.dumps(check(), indent=2))
