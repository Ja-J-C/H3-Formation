#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
formation_time_v5.py  –  生成帧 = 首次 r_maxHH≤1.3 Å  且尾段单调
"""

import argparse, itertools, pathlib, re, sys
import numpy as np

# ---------- 阈值 (Å) ----------
CUTOFF_HH   = 2.1     # 在参考帧锁定 H3+
R_CONTACT   = 1.3     # r_maxHH ≤ 1.3 Å → H3+ 已聚束
TOL_DIST    = 0.005   # 单调容忍
R_SEP       = 2.6     # （可选）完全分离阈值
R_HH_BOUND  = 1.3     # （可选）分离帧仍束缚

SKIP_FRAMES = 60      # 忽略末尾 20 帧
ITER_DT     = 0.001   # fs / iteration
ITER_PER_FRAME = 500  # iteration / frame

MASS = {"H":1.00784,"C":12,"N":14.0067,"O":15.999}

# ---------- 解析 xyz ----------
def parse_xyz(p):
    with p.open() as f:
        while True:
            n = f.readline()
            if not n: break
            nat = int(n.strip())
            com = f.readline().strip()
            it  = int(re.search(r'iter\s*=\s*(\d+)',com,re.I).group(1))
            sym,xyz=[],[]
            for _ in range(nat):
                s,*xyzf = f.readline().split()
                sym.append(s); xyz.append([float(x) for x in xyzf])
            yield it,sym,np.asarray(xyz)

def com(crd,idx,sym):
    idx=np.asarray(idx); m=np.array([MASS[sym[i]] for i in idx])
    return (crd[idx]*m[:,None]).sum(0)/m.sum()

# ---------- 主 ----------
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("-i","--input",default="trajectory.xyz");args=ap.parse_args()
    traj=pathlib.Path(args.input); frames=list(parse_xyz(traj))
    end_idx=len(frames)-SKIP_FRAMES-1
    # ---- 锁定三氢簇 ----
    _,sym_end,xyz_end=frames[end_idx]
    h_idx=[i for i,s in enumerate(sym_end) if s=="H"]
    trio,min_r=None,1e9
    for t in itertools.combinations(h_idx,3):
        rmax=max(np.linalg.norm(xyz_end[i]-xyz_end[j])
                 for i,j in itertools.combinations(t,2))
        if rmax<CUTOFF_HH and rmax<min_r: trio,min_r=list(t),rmax
    if trio is None: sys.exit("No H3+ found in ref frame.")
    h3_idx=trio
    # ---- 预计算量 ----
    iters,dCOM,minDist,maxHH=[],[],[],[]
    rest_idx=[i for i in range(len(sym_end)) if i not in h3_idx]
    for it,sym,xyz in frames:
        rest=[i for i in range(len(sym)) if i not in h3_idx]
        iters.append(it)
        com_h=com(xyz,h3_idx,sym); com_p=com(xyz,rest,sym)
        dCOM.append(np.linalg.norm(com_h-com_p))
        A=xyz[h3_idx][:,None,:]; B=xyz[rest][None,:,:]
        minDist.append(np.linalg.norm(A-B,axis=2).min())
        maxHH.append(max(np.linalg.norm(xyz[p]-xyz[q])
                         for p,q in itertools.combinations(h3_idx,2)))
    dCOM=np.asarray(dCOM);maxHH=np.asarray(maxHH);minDist=np.asarray(minDist);iters=np.asarray(iters)
    # ---- 从头找生成帧 ----
    gen_idx=None
    for i in range(0,end_idx+1):
        if maxHH[i]<=R_CONTACT:
            tail=dCOM[i:end_idx+1]
            if np.all(np.diff(tail)>=-TOL_DIST):
                gen_idx=i;break
    if gen_idx is None: sys.exit("No frame meets formation criterion.")
    # ---- 可选：分离帧 ----
    sep_idx=gen_idx
    while sep_idx<=end_idx and minDist[sep_idx]<=R_SEP: sep_idx+=1
    # ---- 输出 ----
    def pr(lbl,idx):
        print(f"{lbl:<14} at iter {iters[idx]:>8d}  (~{iters[idx]*ITER_DT:7.3f} fs, frame #{idx})")
    pr("H3+ formation",gen_idx)
    if sep_idx<=end_idx and maxHH[sep_idx]<=R_HH_BOUND:
        pr("H3+ separates",sep_idx)
    np.savetxt(traj.with_name("h3p_formation.txt"),
               np.column_stack([iters,dCOM,minDist]),
               header="iteration COM_A minContact_A")

if __name__=="__main__": main()
