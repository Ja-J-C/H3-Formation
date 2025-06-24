#!/bin/bash

# -------- 原有参数 ----------

start=1

end=1350

base_dir="."

# ----------------------------



# ============ 新增：统计表 ============

declare -A CNT     # CNT["finished"], CNT["fragment:CH3+CH3"] ...

# =====================================



# --------- Awk 片段保持不变 ----------

awk_frag(){

cat <<'AWK'

BEGIN{th=2.0; th2=th*th}

function dist2(i,j){dx=x[i]-x[j];dy=y[i]-y[j];dz=z[i]-z[j]; return dx*dx+dy*dy+dz*dz}

function find(a){return parent[a]==a?a:parent[a]=find(parent[a])}

{elem[NR]=$1;x[NR]=$2;y[NR]=$3;z[NR]=$4;parent[NR]=NR}

END{

 n=NR

 for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)if(dist2(i,j)<th2){ri=find(i);rj=find(j);if(ri!=rj)parent[rj]=ri}

 for(i=1;i<=n;i++){root=find(i);comp[root]=comp[root] elem[i]","}

 out="";first=1

 for(root in comp){

    split(comp[root],arr,","); delete count

    for(k in arr){e=arr[k];if(e!="")count[e]++}

    formula="";for(e in count){formula=formula e count[e]}

    if(!first)out=out"+";out=out formula;first=0

 }

 print out

}

AWK

}

# --------------------------------------



for ((idx=start; idx<=end; idx++)); do

  folder="td${idx}"

  path="$base_dir/$folder"

  traj="$path/trajectory.xyz"

  control="$path/control.inp"

  monitor="$path/monitor.out"

  errfile="$path/error"



  [[ ! -d "$path" ]] && continue



  reason=""; complete=false; prod=""



  # --- fragmentation 判定 ---

  if [[ -f "$traj" ]]; then

    natoms=$(head -n 1 "$traj"); (( natoms<1 )) && natoms=0

    frame_size=$((natoms+2))

    tail -n "$frame_size" "$traj" | tail -n "$natoms" > __last.xyz

    if awk '{x[NR]=$2;y[NR]=$3;z[NR]=$4}

            END{for(i=1;i<=NR;i++)for(j=i+1;j<=NR;j++){d=(x[i]-x[j])^2+(y[i]-y[j])^2+(z[i]-z[j])^2;if(d>25){exit 0}};exit 1}' __last.xyz

    then

       complete=true; reason="fragmented"; prod=$(awk -f <(awk_frag) __last.xyz)

    fi

    rm -f __last.xyz

  fi



  # --- finished ---

  if [[ "$complete" == false && -f "$monitor" ]]; then

     if tail -n1 "$monitor" | grep -q "Run finished:"; then

        complete=true; reason="finished"

     fi

  fi



  # --- dft error ---

  if [[ "$complete" == false && -s "$errfile" ]] && grep -qi "dft" "$errfile"; then

     complete=true; reason="dft error"

 
  fi



  # 温度信息

  temp=""; [[ -f "$control" ]] && temp=$(grep -i "temperature_ions" "$control" | head -n1 | tr -d '[:space:]')

  [[ -n "$temp" ]] && temp=" [$temp]"



  # -------- 输出（保持原格式）--------

  if [[ "$complete" == true ]]; then

     if [[ "$reason" == "fragmented" ]]; then

        echo "$folder complete ($reason: $prod)$temp"

        key="fragment:$prod"

     else

        echo "$folder complete ($reason)$temp"

        key="$reason"

     fi

     # ------------- 新增计数 -------------

     CNT["$key"]=$(( CNT["$key"] + 1 ))

  fi

done



# ============ 打印 Summary ============

echo "----- Summary -----"

for k in "${!CNT[@]}"; do

    printf "%-20s : %d\n" "$k" "${CNT[$k]}"

done

echo "-------------------"


