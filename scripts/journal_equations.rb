#!/usr/bin/env ruby
# Exact replay of the mixed minors in Schlecht and Habets, Appendix B, p. 1563.
require "matrix"
require "json"

i = Complex(0r, 1r)
k = Matrix[[0,i,1,1],[-i,0,1,1],[1,1,0,1],[1,1,0,0]]
identity = Matrix.identity(4)
h = k * (i / 2)
a = (identity + h) * (identity - h).inverse
d = Matrix.diagonal(3r, 1r/3, 1r, 1r)
b = d.inverse * a.conjugate.inverse * d
raise "inverse normalization" unless d * b * d.inverse * a.conjugate == identity

def minor(m, rows, cols)
  return 1r if rows.empty?
  Matrix.build(rows.size, cols.size) { |j,l| m[rows[j],cols[l]] }.det
end

indices = (0...4).to_a
(0..4).each do |n|
  indices.combination(n).each do |s|
    raise "principal minors" unless minor(a,s,s) == minor(b,s,s)
  end
end

# Direct comparison with every entry displayed in (69) and (70).
f2 = 9r
f3 = 3r + 3r*i/2
e4 = (12r - 6r*i)/5
raise "(69)" unless a.row(2).to_a.first(2) == [a[0,2]*f3, a[1,2]*f3/f2] &&
                    a.row(3).to_a.first(2) == [a[0,3]*e4, a[1,3]*e4/f2]
expected_b = Matrix.build(4) do |r,c|
  next a[1,0]/f2 if [r,c] == [0,1]
  next a[0,1]*f2 if [r,c] == [1,0]
  a[r,c]
end
raise "(70)" unless b == expected_b

u = [0,2] # printed indices 1,3
v = [1,3] # printed indices 2,4
checks = {"71" => [minor(a,u,v),minor(b,v,u)], "72" => [minor(a,v,u),minor(b,u,v)]}

# For these complementary index pairs the Jacobi sign is positive.
# Test the diagonal scaling, complementary indices, determinant and conjugation.
[[u,v],[v,u]].each do |rows,cols|
  factor = cols.map { |x| d[x,x] }.reduce(:*) / rows.map { |x| d[x,x] }.reduce(:*)
  jacobi = factor * (minor(a,indices-cols,indices-rows) / a.det).conjugate
  raise "Jacobi" unless minor(b,rows,cols) == jacobi
end
product = (a[0,1]*f2 - a[1,0]) * (a[2,3] - f2*a[3,2])
raise "unexpected equality" if checks.values.any? { |left,right| left == right } || product == 0
raise "fixed (71) check" unless checks["71"] == [(16-20*i)/41,(162-18*i)/41]

def components(z)
  [z.real.to_r.to_s, z.imag.to_r.to_s]
end
puts JSON.pretty_generate({
  "numbering" => "IEEE TSP 65(6) p. 1563, one-based row and column labels",
  "det_A" => components(a.det), "equal_principal_minors" => 16,
  "mixed_minors_left_right" => checks.transform_values { |pair| pair.map { |z| components(z) } },
  "equation_73_product" => components(product), "correct_jacobi_identities_verified" => 2
})
