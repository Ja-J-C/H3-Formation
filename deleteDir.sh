#SBATCH --ntasks-per-node=1



#SBATCH --cpus-per-task=1



#SBATCH --time=1:59:59



for ((i=2;i<=100;i++));do



        rm  -r  "td$i"



       



done
