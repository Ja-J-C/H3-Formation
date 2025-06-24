

  

#SBATCH --ntasks-per-node=1

#SBATCH --cpus-per-task=1

#SBATCH --time=71:59:59

for ((i=1112415;i<=1112425;i++));do

qdel "$i"

done
