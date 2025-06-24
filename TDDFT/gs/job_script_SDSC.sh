#!/bin/bash

#SBATCH --job-name=gs_test

#SBATCH --account=van128

#SBATCH --partition=shared

#SBATCH --nodes=1

#SBATCH --ntasks=1

#SBATCH --mem=2GB

#SBATCH --ntasks-per-node=1

#SBATCH --cpus-per-task=1

#SBATCH --time=47:59:59



module load cpu/0.17.3b  intel/19.1.3.304/6pv46so fftw/3.3.10/jq4mbmk intel-mkl/2020.4.304/vg6aq26



dftdir=/home/cjiang2/varga_dft_code_serial/release/



cd $SLURM_SUBMIT_DIR



$dftdir/dft > output 2> error


