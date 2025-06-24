#!/bin/bash

#SBATCH --job-name=propane_td101

#SBATCH --account=van128

#SBATCH --partition=shared

#SBATCH --nodes=1

#SBATCH --ntasks=5

#SBATCH --mem-per-cpu=2GB

#SBATCH --ntasks-per-node=5

#SBATCH --cpus-per-task=1

#SBATCH --time=47:59:59



module load cpu/0.17.3b  intel/19.1.3.304/6pv46so fftw/3.3.10/jq4mbmk intel-mkl/2020.4.304/vg6aq26 intel-mpi/2019.10.317/ezrfjne



dftdir=/home/cjiang2/varga_dft_code_parallel/release/



cd $SLURM_SUBMIT_DIR



mpirun -n 4 $dftdir/dft > output 2> error
