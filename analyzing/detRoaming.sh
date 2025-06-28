#!/usr/bin/env python3

import sys, os

import math

from pathlib import Path



# ---------------- Geometry helper ----------------

def dist2(a, b):

    return (a[0]-b[0])**2 + (a[1]-b[1])**2 + (a[2]-b[2])**2



# ------------- Frame iterator --------------------

def frames_from_xyz(fname):

    with open(fname) as fh:

        while True:

            line = fh.readline()

            if not line:

                break

            line = line.strip()

            if not line.isdigit():

                continue

            nat = int(line)

            fh.readline()  # comment

            frame = []

            for _ in range(nat):

                el, *xyz = fh.readline().split()[:4]

                frame.append((el, tuple(map(float, xyz))))

            yield frame



# ------- Single-file roaming test ---------------

def has_roaming_H2_block(path, need_frames=140, hh_cut=1.3, hx_cut=2.0):

    hh2 = hh_cut**2

    hx2 = hx_cut**2

    consec = 0



    for frame in frames_from_xyz(path):

        # 找出所有氢原子

        h_idx = [i for i,(el,_) in enumerate(frame) if el.upper()=='H']

        coords = [coord for _,coord in frame]

        roaming = False



        for i,hi in enumerate(h_idx):

            for hj in h_idx[i+1:]:

                if dist2(coords[hi], coords[hj]) >= hh2:

                    continue

                # 检查孤立性

                iso = True

                for k,(_,crd) in enumerate(frame):

                    if k in (hi,hj): continue

                    if dist2(coords[hi],crd) < hx2 or dist2(coords[hj],crd) < hx2:

                        iso = False

                        break

                if iso:

                    roaming = True

                    break

            if roaming:

                break



        consec = consec+1 if roaming else 0

        if consec >= need_frames:

            return True



    return False



# ------- Find all trajectory files ---------------

def find_trajectories(root):

    trajs = []

    for dirpath, dirnames, filenames in os.walk(root):

        base = os.path.basename(dirpath)

        if base.startswith('td') and 'trajectory.xyz' in filenames:

            trajs.append(Path(dirpath)/'trajectory.xyz')

    return sorted(trajs)



# --------------- Main ----------------------------

def main():

    root = Path(sys.argv[1] if len(sys.argv)>1 else '.').resolve()

    if not root.is_dir():

        sys.exit(f"Error: {root} is not a directory")



    print(f"Scanning root directory: {root}\n")

    trajectories = find_trajectories(root)

    if not trajectories:

        sys.exit("❌ 没有在任何 td*/trajectory.xyz 中发现轨迹文件，请检查路径是否正确。")



    print("✅ 找到以下 trajectory.xyz 文件：")

    for t in trajectories:

        print("  -", t)

    print()



    need = 140  # 70 fs / 0.5 fs

    for traj in trajectories:

        tdname = traj.parent.name

        ok = has_roaming_H2_block(traj, need_frames=need)

        print(f"{tdname:<20} H2 roaming: {'yes' if ok else 'no'}")



if __name__=='__main__':

    main()


