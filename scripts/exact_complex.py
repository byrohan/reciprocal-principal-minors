#!/usr/bin/env python3
"""Order-four example. Gaussian integers as pairs of Python integers.
All comparisons after clearing denominators. No floating-point complex numbers."""
from itertools import permutations
from pathlib import Path
from functools import reduce
from fractions import Fraction as Q
import json
import sys
from exact_real import subsets, sub, require, strongly_connected

Z, U, I = (0,0), (1,0), (0,1)

def plus(x,y):
    return x[0]+y[0],x[1]+y[1]

def times(x,y):
    return x[0]*y[0]-x[1]*y[1], x[0]*y[1]+x[1]*y[0]

def conjugate(x):
    return x[0],-x[1]

def power(x,k):
    return reduce(times,[x]*k,U)

def det(m):
    acc = Z
    for p in permutations(range(len(m))):
        sign=(-1)**sum(a>b for i,a in enumerate(p) for b in p[i+1:])
        acc=plus(acc,reduce(times,(m[i][j] for i,j in enumerate(p)),(sign,0)))
    return acc

def matmul(a,b):
    return [[reduce(plus,(times(x,y) for x,y in zip(row,col)),Z) for col in zip(*b)] for row in a]

def adj(a):
    n=len(a)
    keep=[[j for j in range(n) if j!=i] for i in range(n)]
    return [[times(((-1)**(i+j),0),det(sub(a,keep[j],keep[i]))) for j in range(n)] for i in range(n)]

def quotient(x,y):
    numerator=times(x,conjugate(y))
    norm=y[0]**2+y[1]**2
    return tuple(Q(z)/norm for z in numerator)

def check_equation_71(k):
    """Normalize the half-parameter pair exactly as in (69)-(70) of arXiv v1."""
    n=len(k)
    def shift(sign):
        return [[plus((2*int(i==j),0),times((0,sign),k[i][j])) for j in range(n)] for i in range(n)]
    l,r=shift(-1),shift(1)
    a=[[quotient(z,det(l)) for z in row] for row in matmul(r,adj(l))]
    raw=[[conjugate(quotient(z,det(r))) for z in row] for row in matmul(l,adj(r))]
    d=[Q(3),Q(1,3),Q(1),Q(1)]
    b=[[times(raw[i][j],(d[j]/d[i],0)) for j in range(n)] for i in range(n)]
    f2=(9,0)
    f3=quotient(a[2][0],a[0][2])
    e4=quotient(a[3][0],a[0][3])
    require(a[2][1]==quotient(times(a[1][2],f3),f2) and
            a[3][1]==quotient(times(a[1][3],e4),f2),'normal form 69')
    require(all(a[i][j]==b[i][j] for i in range(n) for j in range(n) if (i,j) not in [(0,1),(1,0)])
            and b[0][1]==quotient(a[1][0],f2) and b[1][0]==times(a[0][1],f2),'normal form 70')
    left=det(sub(a,[0,2],[1,3]))
    right=det(sub(b,[1,3],[0,2]))
    require(left==(Q(16,41),Q(-20,41)) and right==(Q(162,41),Q(-18,41)), 'equation 71')
    return {'f2':9,'f3':list(map(str,f3)),'e4':list(map(str,e4)),
            'left_re_im':list(map(str,left)),'right_re_im':list(map(str,right))}

def solve():
    k=[[Z,I,U,U],[(0,-1),Z,U,U],[U,U,Z,U],[U,U,Z,Z]]
    n=len(k)
    def shift(sign):
        return [[plus((int(i==j),0),times((0,sign),k[i][j])) for j in range(n)] for i in range(n)]
    l,r=shift(-1),shift(1)
    da,db=det(l),det(r)
    require(da!=Z and db!=Z,'Cayley denominators')
    a,b=matmul(r,adj(l)),matmul(l,adj(r))
    both=times(da,db)
    unit=[[both if i==j else Z for j in range(n)] for i in range(n)]
    require(matmul(a,b)==matmul(b,a)==unit,'two-sided Gaussian inverse')
    require(strongly_connected([[x!=Z for x in row] for row in a]),'irreducibility')
    ca=[[conjugate(x) for x in row] for row in a]
    ct=list(map(list,zip(*ca)))
    minors=[]
    for mask,s in subsets(n):
        x,y=det(sub(ca,s,s)),det(sub(b,s,s))
        require(times(x,power(db,len(s)))==times(y,power(conjugate(da),len(s))),'complex minor '+str(mask))
        minors.append([mask,x,y])
    def cycle_obstruction(m):
        for length in range(1,n+1):
            for p in permutations(range(n),length):
                edges=list(zip(p,p[1:]+p[:1]))
                x=reduce(times,(m[i][j] for i,j in edges),U)
                y=reduce(times,(b[i][j] for i,j in edges),U)
                left=times(x,power(db,length))
                right=times(y,power(conjugate(da),length))
                if left!=right:
                    return dict(cycle=p,cross_multiplied=[left,right])
        raise ArithmeticError('missing cycle obstruction')
    return dict(equation_71=check_equation_71(k),K=k,A_numerator=a,A_denominator=da,B_numerator=b,B_denominator=db,
                both_products_checked=True,minors_numerators= minors,
                conjugate_obstruction=cycle_obstruction(ca),adjoint_obstruction=cycle_obstruction(ct))

if __name__=='__main__':
    path=Path(sys.argv[1]);path.mkdir(parents=True,exist_ok=True)
    result=solve()
    (path/'four-complex.json').write_text(json.dumps(result,indent=2)+'\n')
    print('16 complex principal minors and both cycle obstructions verified.')
