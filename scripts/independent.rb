#!/usr/bin/env ruby
# A second implementation using Ruby's standard Matrix, Rational and Complex.
# No inputs from Python, JSON records or Lean.
require 'matrix'
require 'json'
def require_equal(a,b,label)
  raise "#{label}: #{a.inspect} differs from #{b.inspect}" unless a == b
end

def principal(m, indices)
  return 1 if indices.empty?
  Matrix.build(indices.size) { |i,j| m[indices[i],indices[j]] }.det
end

def cayley(h)
  id=Matrix.identity(h.row_count)
  (id+h)*(id-h).inverse
end

# Store numerator/denominator pairs independently of Ruby's numeric printing.
def components(x)
  [x.real, x.imag].map { |v| [v.numerator, v.denominator] }
end

def pair(h, t, complex: false)
  a=cayley(t*h)
  b=a.inverse
  original=complex ? a.conjugate : a
  n=a.row_count
  require_equal(b,cayley(-t*h),'second inverse')
  minors=(0...(1<<n)).map do |mask|
    s=(0...n).select { |j| mask[j]==1 }
    x=principal(original,s)
    require_equal(x,principal(b,s),'labeled minor')
    x
  end
  # Exhaust every simple directed cycle, including loops.
  # One unequal product suffices to disprove diagonal similarity over C.
  [original,original.transpose].each do |candidate|
    obstructed=(1..n).any? do |k|
      (0...n).to_a.permutation(k).any? do |v|
        w=v.rotate
        v.zip(w).map { |i,j| candidate[i,j] }.reduce(1,:*) !=
          v.zip(w).map { |i,j| b[i,j] }.reduce(1,:*)
      end
    end
    raise 'missing obstruction' unless obstructed
  end
  {order:n, exact_minors:minors.size, determinant:components(a.det),
   distinct_minors:minors.map { |z| components(z) }.uniq, positive_real:!complex && minors.all?(&:positive?)}
end

h6=Matrix[[0,1,-1,1,0,0],[-1,0,1,0,0,0],[1,-1,0,0,0,0],
          [0,0,0,0,1,0],[0,0,0,0,0,1],[1,0,0,0,0,0]]
h5=Matrix[[0,-1,1,0,0],[1,0,1,0,0],[1,1,0,1,0],
          [0,0,0,0,1],[-2,-2,0,0,0]]
i=Complex(0,1)
k=Matrix[[0,i,1,1],[-i,0,1,1],[1,1,0,1],[1,1,0,0]]
j=Matrix.diagonal(1,-2)
example=Matrix[[3,2],[-4,-3]]
require_equal(example*j*example.transpose,j,'indefinite metric')
res=[pair(h6,1r),pair(h6,1/2r),pair(h5,1r),pair(h5,1/2r),pair(k,i,complex:true)]
a=cayley(i*k/2r)
d=Matrix.diagonal(3,1/3r,1,1)
b=d.inverse*a.inverse.conjugate*d
lhs=Matrix.build(2){|r,c| a[[0,2][r],[1,3][c]]}.det
rhs=Matrix.build(2){|r,c| b[[1,3][r],[0,2][c]]}.det
require_equal(lhs,Complex(16/41r,-20/41r),'equation (71), LHS')
require_equal(rhs,Complex(162/41r,-18/41r),'equation (71), RHS')
puts JSON.pretty_generate({implementation:RUBY_DESCRIPTION,pairs:res,equation_71:[components(lhs),components(rhs)]})
