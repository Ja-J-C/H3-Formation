#!/bin/bash



output_file="numE"

> "$output_file"



# 使用数值排序：提取所有 tdlasert 目录，按数字后缀排序

for dir in $(ls -d tdlasert* 2>/dev/null | sort -V); do

    if [ -d "$dir" ]; then

        energy_file="$dir/orbital_energy_components.dat"



        if [ -f "$energy_file" ]; then

            last_line=$(tail -n 1 "$energy_file")

            echo "$dir: $last_line" >> "$output_file"

        else

            echo "$dir: [orbital_energy_components.dat not found]" >> "$output_file"

        fi

    fi

done



echo "✅ Done. Results saved to $output_file"

