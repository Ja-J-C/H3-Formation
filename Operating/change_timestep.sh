#SBATCH --ntasks-per-node=1

#SBATCH --cpus-per-task=1

#SBATCH --time=71:59:59

for ((i=52;i<=58;i++));do

cd "td$i"
sed -i "s/N_time_steps=1000000/N_time_steps=150000/" control.inp

cd ..

done
