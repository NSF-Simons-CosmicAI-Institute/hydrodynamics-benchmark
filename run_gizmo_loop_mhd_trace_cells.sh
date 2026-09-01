#!/bin/bash
#SBATCH -J run_gizmo_loop_mhd
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -o log.%j 
#SBATCH -p rtx
#SBATCH -A XXXXXXX
#SBATCH -t 24:00:00

# Load the requisite modules
module purge
module load TACC intel impi hdf5/1.10.4 gsl fftw3
module load tacc-apptainer

# Exit upon failure
set -e

# Set OMP threads
export OMP_NUM_THREADS=2

# Define the unchanging simulation parameters
R=1.5
alpha=2.0

# Root directory
root_dir=$(pwd)

# Virtual environment directory
venv_dir=/work2/10386/lsmith9003/frontera/python-envs/gizmo/
export PYTHONPATH=/work2/10386/lsmith9003/frontera/python-envs/gizmo/lib/python3.9/site-packages/
export PATH=$PYTHONPATH:$PATH

# Start time
start=`date +%s`

# Set up a loop for the remaining simulation parameters
for M in 150 600 2400
do
	for seed in 1 42
	do
		# General setup
		echo "----------------------"
		echo "Running trace_cells pipeline for: "
		echo "R = $R, Alpha = $alpha, M = $M, Turb_Seed = $seed"
		date
		run_dir="$root_dir/MHD_R${R}_alpha${alpha}_M${M}_seed${seed}"
		echo "General setup complete."

		# Trace cells
		echo "Running TraceCells..."
		date
		cd $run_dir
		cp -r $root_dir/src/trace_cells .
		cd trace_cells
                source $venv_dir/bin/activate
		python -u trace_cells_mhd.py --gizmo_path $run_dir/output --mass 'M'$M --radius $R > log.trace_cells
                deactivate
		cd $root_dir
		echo "TraceCells complete."
		date
	done
done 

# End time 
end=`date +%s`
runtime=$((end-start))
echo "$runtime"
