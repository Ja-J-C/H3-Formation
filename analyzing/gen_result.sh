#!/bin/bash


start=1      # 起始编号

end=200        # 结束编号

base_dir="."       # td 文件夹所在路径



declare -A CNT

sum750=0

cnt750=0



for (( idx=start; idx<=end; idx++ )); do

    folder="${base_dir}/td${idx}"

    monitor="${folder}/monitor.out"



    [[ -f "$monitor" ]] || { echo "td${idx}  (missing monitor.out)"; continue; }



    # 读取运行状态

    line=$(grep -m1 -E '^Run (finished|fragmented|terminated)' "$monitor")

    [[ -z "$line" ]] && { echo "td${idx}  (running or no status yet)"; continue; }



    reason=""

    product=""

    if   [[ "$line" =~ Run\ finished ]]; then

        reason="finished"

    elif [[ "$line" =~ Run\ fragmented ]]; then

        reason="fragmented"

        product=$(echo "$line" | sed -n 's/.*fragmented: *\([A-Za-z0-9+_-]*\).*/\1/p')

    else

        reason="terminated"

    fi



    # ------- 原有输出 -------

    if [[ "$reason" == "fragmented" ]]; then

        echo "td${idx} complete (fragmented: $product)"

        key="fragmented:$product"

    else

        echo "td${idx} complete ($reason)"

        key="$reason"

    fi

    CNT["$key"]=$((CNT["$key"]+1))

    # -----------------------



    # ------- 抓取并打印 750 fs 数值 -------

    if [[ "$reason" == "finished" ]]; then

        val=$(awk '/^INFOLINE:/ && ($2+0)==750 { print $3; exit }' "$monitor")

        if [[ -n "$val" ]]; then

            echo "        750fs value = $val   (td${idx})"

            sum750=$(awk -v a="$sum750" -v b="$val" 'BEGIN{printf "%.10f", a+b}')

            cnt750=$((cnt750+1))

        else

            echo "        750fs value = N/A   (td${idx})"

        fi

    fi

    # --------------------------------------

done



# -------- Summary --------

echo "----- Summary -----"

for k in "${!CNT[@]}"; do

    printf "%-25s : %d\n" "$k" "${CNT[$k]}"

done



if [[ $cnt750 -gt 0 ]]; then

    avg750=$(awk -v s="$sum750" -v n="$cnt750" 'BEGIN{printf "%.10f", s/n}')

    echo "avg 750fs value (finished runs) : $avg750    (N=$cnt750)"

fi

echo "---------------------"


