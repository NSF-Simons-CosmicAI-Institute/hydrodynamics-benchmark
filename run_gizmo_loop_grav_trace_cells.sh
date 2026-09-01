#!/bin/bash
#SBATCH -J run_gizmo_loop_grav
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -o log.%j 
#SBATCH -p rtx
#SBATCH -A XXXXXXX
#SBATCH -t 4:00:00

# Load the requisite modules
module purge
module load TACC intel impi hdf5/1.10.4 gsl fftw3
module load tacc-apptainer

# Exit upon failure
set -e

# Set OMP threads
export OMP_NUM_THREADS=2

# Define the unchanging simulation parameters
M=6

# Root directory
root_dir=$(pwd)

# Virtual environment directory
venv_dir=/work2/10386/lsmith9003/frontera/python-envs/gizmo/
export PYTHONPATH=/work2/10386/lsmith9003/frontera/python-envs/gizmo/lib/python3.9/site-packages/
export PATH=$PYTHONPATH:$PATH

# Start time
start=`date +%s`

# Set up a loop for the remaining simulation parameters
for R in 0.025 0.05 0.1 0.2
do
		# General setup
		echo "----------------------"
		echo "Running grav_collapse pipeline for: "
		echo "R = $R, M = $M"
		date
		run_dir="$root_dir/grav_R${R}_M${M}"
		echo "General setup complete."

		# Trace cells
		echo "Running TraceCells..."
		date
		cd $run_dir
		cp -r $root_dir/src/trace_cells .
		cd trace_cells
                source $venv_dir/bin/activate
		python -u trace_cells_grav.py --gizmo_path $run_dir/output --mass 'M'$M --radius $R > log.trace_cells
                deactivate
		cd $root_dir
		echo "TraceCells complete."
		date
done 

# End time 
end=`date +%s`
runtime=$((end-start))
echo "$runtime"
