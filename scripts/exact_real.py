#!/usr/bin/env python3
"""Exact referee checks. Standard Python only. No imports from the original verifier."""
from fractions import Fraction as Q
from itertools import combinations, product
from math import lcm, prod
from pathlib import Path
import argparse
import csv
import json
import re

def require(test, message):
    if not test:
        raise ArithmeticError(message)

def transpose(a):
    return list(map(list, zip(*a)))

def multiply(a, b):
    return [[sum(x*y for x,y in zip(row,col)) for col in transpose(b)] for row in a]

def eye(n):
    return [[int(i == j) for j in range(n)] for i in range(n)]

def sub(a, rows, cols):
    return [[a[i][j] for j in cols] for i in rows]

def det(a):
    """Bareiss elimination with row pivoting, including the empty determinant."""
    n = len(a)
    if not n:
        return Q(1)
    b = [list(map(Q, row)) for row in a]
    sign = previous = 1
    for k in range(n-1):
        pivot = next((j for j in range(k,n) if b[j][k]), None)
        if pivot is None:
            return Q(0)
        if pivot != k:
            b[k], b[pivot] = b[pivot], b[k]
            sign = -sign
        for i in range(k+1,n):
            for j in range(k+1,n):
                b[i][j] = (b[k][k]*b[i][j] - b[i][k]*b[k][j])/previous
        previous = b[k][k]
    return sign*b[-1][-1]

def inverse(a):
    """Adjugate formula; does not solve a linear system by augmentation."""
    n, d = len(a), det(a)
    require(d, 'singular inverse')
    omit = [[j for j in range(n) if j != i] for i in range(n)]
    return [[(-1)**(i+j)*det(sub(a,omit[j],omit[i]))/d for j in range(n)] for i in range(n)]

def shifted(h, t):
    return [[int(i==j)+t*x for j,x in enumerate(row)] for i,row in enumerate(h)]

def cayley(h, t):
    return multiply(shifted(h,t), inverse(shifted(h,-t)))

def six_generator():
    return [[0,1,-1,1,0,0],[-1,0,1,0,0,0],[1,-1,0,0,0,0],
            [0,0,0,0,1,0],[0,0,0,0,0,1],[1,0,0,0,0,0]]

def five_generator():
    return [[0,-1,1,0,0],[1,0,1,0,0],[1,1,0,1,0],
            [0,0,0,0,1],[-2,-2,0,0,0]]

def subsets(n):
    for mask in range(1<<n):
        yield mask,[i for i in range(n) if mask>>i & 1]

def strongly_connected(a):
    for start in range(len(a)):
        seen, todo = {start}, [start]
        while todo:
            for j,x in enumerate(a[todo.pop()]):
                if x and j not in seen:
                    seen.add(j)
                    todo.append(j)
        if len(seen) != len(a):
            return False
    return True

def diagonal_equivalent(a,b):
    """Solve a_ij d_j = d_i b_ij by exact ratio propagation, in each component.
    All nonzero coefficients are rational; a conflict also excludes complex d."""
    n = len(a)
    edges = [[] for _ in a]
    for i,j in product(range(n), repeat=2):
        x,y = a[i][j],b[i][j]
        if bool(x) != bool(y):
            return False
        if x:
            r = Q(y)/x
            edges[i].append((j,r))
            edges[j].append((i,1/r))
    d = {}
    for root in range(n):
        if root in d:
            continue
        d[root] = Q(1)
        todo = [root]
        while todo:
            i = todo.pop()
            for j,r in edges[i]:
                if j in d:
                    if d[j] != d[i]*r:
                        return False
                else:
                    d[j] = d[i]*r
                    todo.append(j)
    return True

def from_lean(name):
    source=(Path(__file__).resolve().parents[1] / 'ReciprocalMinors/Six.lean').read_text()
    body=re.search(r'\bdef '+name+r'\s*:.*?!!\[(.*?)\]',source,re.S).group(1)
    return [[int(v) for v in row.split(',')] for row in body.split(';')]

def integral_form(a):
    scale=lcm(*(Q(x).denominator for row in a for x in row))
    return scale, [[int(scale*x) for x in row] for row in a]

def check_pair(h,t,label,rows):
    a=cayley(h,t)
    b=inverse(a)
    n=len(a)
    require(b==cayley(h,-t) and multiply(a,b)==eye(n) and multiply(b,a)==eye(n),label+' inverse')
    require(strongly_connected(a) and strongly_connected(b),label+' support')
    require(not diagonal_equivalent(a,b) and not diagonal_equivalent(transpose(a),b),label+' similarity')
    for mask,s in subsets(n):
        m=det(sub(a,s,s))
        c=[i for i in range(n) if i not in s]
        v=det(sub(b,s,s))
        require(m==v==det(sub(a,c,c))/det(a),label+' minor '+str(mask))
        require(len(s)%2==0 or det(sub(h,s,s))==0,label+' odd generator minor')
        rows.append((label,mask,' '.join(map(str,s)),str(m),str(v)))
    da,na=integral_form(a)
    db,nb=integral_form(b)
    if label=='six_integer':
        require((da,db)==(1,1) and (na,nb)==(from_lean('aZ'),from_lean('bZ')),label+' transcription')
    if label=='six_dense':
        require((da,db)==(107,107) and (na,nb)==(from_lean('denseNumerator'),from_lean('denseInvNumerator')),label+' transcription')
        require(all(x for row in a+b for x in row) and all(Q(row[3])>0 for row in rows if row[0]==label),'dense and positive')
    if label=='five_dense':
        require(all(x for row in a+b for x in row),'order-five density')
        require(min(Q(row[3]) for row in rows if row[0]==label)==Q(1,2),'order-five positivity')
    deletions=[]
    for k in range(n):
        s=[i for i in range(n) if i!=k]
        aa,bb=sub(a,s,s),sub(b,s,s)
        deletions.append({'removed':k,'direct':diagonal_equivalent(aa,bb),'transpose':diagonal_equivalent(transpose(aa),bb),
                          'inverse':multiply(aa,bb)==eye(n-1),'irreducible_A':strongly_connected(aa),
                          'product_00':str(multiply(aa,bb)[0][0])})
    return dict(name=label,dimension=n,determinant=str(det(a)),scale=da,numerator=na,
                inverse_scale=db,inverse_numerator=nb,deletions=deletions,trace=str(sum(a[i][i] for i in range(n))),
                distinct_minors=sorted({r[3] for r in rows if r[0]==label},key=Q))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('out',type=Path)
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    rows=[]
    results=[check_pair(six_generator(),Q(1),'six_integer',rows),
             check_pair(six_generator(),Q(1,2),'six_dense',rows),check_pair(five_generator(),Q(1),'five',rows),
             check_pair(five_generator(),Q(1,2),'five_dense',rows)]
    with (args.out/'all-minors.csv').open('w',newline='') as f:
        writer=csv.writer(f, lineterminator='\n')
        writer.writerow(['witness','bitmask','indices_from_zero','minor_A','minor_inverse'])
        writer.writerows(rows)
    (args.out/'certificates.json').write_text(json.dumps(results,indent=2)+'\n')
    print(f'{len(results)} inverse pairs, {len(rows)} corresponding-minor equalities checked.')

if __name__=='__main__':
    main()
