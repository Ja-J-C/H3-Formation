#SBATCH --ntasks-per-node=1



#SBATCH --cpus-per-task=1



#SBATCH --time=71:59:59


mkdir trajectory
for ((i=1;i<=22;i++));do

	cd "td$i"

	scp ./trajectory.xyz ../trajectory
	cd ..
	cd trajectory
	mv trajectory.xyz "trajectory$i"
        cd ..
done
