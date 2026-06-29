#!/bin/bash
#SBATCH -J run_gizmo_loop_mhd
#SBATCH -N 2
#SBATCH -n 56
#SBATCH -o log.%j 
#SBATCH -p normal
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
R=1.5
alpha=2.0

# Root directory
root_dir=$(pwd)

# Virtual environment directory
venv_dir=/work2/10386/lsmith9003/frontera/python-envs/gizmo/ #$root_dir/env
export PYTHONPATH=/work2/10386/lsmith9003/frontera/python-envs/gizmo/lib/python3.9/site-packages/  #$root_dir/env/lib/python3.7/site-packages/
export PATH=$PYTHONPATH:$PATH

# Start time
start=`date +%s`

# Set up a loop for the remaining simulation parameters
for M in 600
do
	for seed in 42
	do
		# General setup
		echo "----------------------"
		echo "Running MHD pipeline for: "
		echo "R = $R, Alpha = $alpha, M = $M, Turb_Seed = $seed"
		date
		run_dir="$root_dir/MHD_R${R}_alpha${alpha}_M${M}_seed${seed}"
		cp -r $root_dir/src/gizmo_imf $run_dir
		cp $root_dir/configs/Config_Rad_MHD.sh $run_dir/Config.sh
		echo "General setup complete."

		# MakeCloud
		echo "Running MakeCloud..."
		date 	
		cp -r $root_dir/src/MakeCloud $run_dir/.
		cd $run_dir/MakeCloud
                source $venv_dir/bin/activate
		./run_makecloud_mhd.sh $R $M $seed $alpha > log.make_cloud
                deactivate
		echo "MakeCloud run complete."

		# Starforge
		echo "Compiling gizmo code base..."
		date
		cd $run_dir
		make > log.make
		echo "Compilation complete."
		
		echo "Running Starforge code..."
		date
		cd $run_dir
		cp -r $run_dir/MakeCloud/output/* .
		filename=$(find . -maxdepth 1 -type f -name "params_*") 
		ibrun ./GIZMO $filename 1>GizmoLogs/RunLogs/Rad_Turb_Sphere_res32.out 2>GizmoLogs/RunLogs/Rad_Turb_Sphere_res32.err
		echo "Starforge run complete."

		# Trace cells
		echo "Running TraceCells..."
		date
		cd $run_dir
		cp -r $root_dir/src/trace_cells .
		cd trace_cells
                source $venv_dir/bin/activate
		python trace_cells.py --gizmo_path $run_dir/output --mass 'M'$M --radius $R > log.trace_cells
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
