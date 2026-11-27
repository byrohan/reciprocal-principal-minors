#!/usr/bin/env python3
"""Bounded falsification test for the real order-four lower-bound proof.
Every zero-diagonal 4x4 matrix with off-diagonal entries in {-1,0,1}.
This finite search supplies evidence only; the manuscript proves the bound."""
from itertools import product
from pathlib import Path
from collections import Counter
import sys,json

def check():
    n=4
    edges=[(i,j) for i in range(n) for j in range(n) if i!=j]
    cuts=[[p for p,(i,j) in enumerate(edges) if (mask>>i)&1 and not (mask>>j)&1] for mask in range(1,15)]
    flips=[[s[i]*s[j] for i,j in edges] for tail in product((-1,1),repeat=3) for s in [(1,)+tail]]
    reverse=[edges.index((j,i)) for i,j in edges]
    tri=[]
    for k in range(n):
        a,b,c=[i for i in range(n) if i!=k]
        tri.append([edges.index(e) for e in ((a,b),(b,c),(c,a),(a,c),(c,b),(b,a))])
    counts=Counter()
    for x in product((-1,0,1),repeat=12):
        counts['enumerated']+=1
        if any(x[a]*x[b]*x[c]+x[d]*x[e]*x[f] for a,b,c,d,e,f in tri):
            continue
        if any(all(x[j]==0 for j in cut) for cut in cuts):
            continue
        counts['irreducible_with_vanishing_odd_minors']+=1
        if any(all(v==0 or sign==-1 for v,sign in zip(x,s)) for s in flips):
            counts['direct_first']+=1
        elif any(all(x[j]*s[j]==-x[reverse[j]] for j in range(12)) for s in flips):
            counts['transpose_only']+=1
        else:
            raise ArithmeticError(x)
    return dict(counts)

if __name__=='__main__':
    target=Path(sys.argv[1])
    target.mkdir(parents=True,exist_ok=True)
    counts=check()
    (target/'small-order-search.json').write_text(json.dumps(counts,indent=2)+'\n')
    print(counts)
