#SBATCH --ntasks-per-node=1



#SBATCH --cpus-per-task=1



#SBATCH --time=1:59:59



for ((i=101;i<=200;i++));do





	cd "td$i"

	sbatch job_script.sh



	cd ..



done
