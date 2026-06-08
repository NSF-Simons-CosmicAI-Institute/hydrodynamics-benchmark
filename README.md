# Astrochemistry Benchmark: Hydrodynamics

This repository hosts the source code used to generate hydrodynamics benchmark data for the CosmicAI Accelerating working group. The code base is made up of three modules, each of which has been adapted/modified from existing software: [Gizmo](https://github.com/pfhopkins/gizmo-public), [MakeCloud](https://github.com/mikegrudic/MakeCloud/tree/master), and trace-cells (in-house post-processing code for SPH simulations).

The following instructions describe how to copy, compile, and run a hydrodynamics simulation. We assume physics driven by either graviational collapse or MHD turbulence, and an initial condition consisting of a turbulent cloud with uniform density. 

## Instructions

1) Log in to frontera and navigate to your scratch directory
``
ssh <username>@frontera.tacc.utexas.edu
cd $SCRATCH
``

2) Copy the source code to your scratch directory:
``
cp -r /work2/10386/lsmith9003/frontera/hydrodynamics-benchmark .
``

3) Create a python virtual environment with the necessary requirements. This step is necessary for generating an initial condition and completing post processing, the scripts for which are written in python:
``
cd hydrodynamics-benchmark
python3 -m venv env
source env/bin/activate
python -m pip install --upgrade pip
python -m pip install --ignore-installed -r requirements.txt
``
Note: the upgrade pip command may throw a error on Frontera (h5py 2.10.0 requires six, which is not installed), but this is a minor pathing issue and can be ignored.

4) Select a run script (either run_gizmo_loop_grav or run_gizmo_loop_mhd) based on the physics of interest, and configure the script to your case/account. This involves inserting your allocation information on line 7:
``
#SBATCH -A XXXXXXX
``
Where the X's are replaced with your TACC allocation code. We list available TACC allocation codes on the [TACC accounts page](https://accounts.tacc.utexas.edu/projects). Note that you can also change the default simulation constants in lines 22-24. 

For a bit more information on how the run script is formatted, the [Frontera user manual](https://docs.tacc.utexas.edu/hpc/frontera/#running-sbatch) has a nice description of Slurm scripts and directives.

5) Submit the job using the SBATCH command:
``
sbatch run_gizmo_loop_grav.sh
``
If everything has been set up according to plan, you should see a series of checks from the Slurm job scheduling system, concluding with:
Submitted batch job <job-ID>
where "job-ID" is a unique identification number assigned to your job by the slurm scheduler.


6) Monitor the job's progress with the squeue command:
``
squeue -u <your-username>
``
This command will list any active job ID's along with their status: either pending (PD) or running (R). The Frontera queues are quite short these days, so you should see the job's status switch to R within one minute or less.

Once the job has started, Slurm will output a log file with the name log.<job-ID>. You should see this script within your run directory as soon as your job begins, and you can open this script (using your text editor of choice) to see detailed updates on how the job is progressing. This log script is also where you will begin the debugging process if the job should fail.

7) Check the simulation output folder. We have configured Gizmo such that it writes the output flowfield at regular intervals. If the simulation is running correctly, hdf5 files should begin appearing in the output directory, which can be viewed with the following command:
``
ls -la $SCRATCH/hydrodynamics-benchmark/grav_R0.1_M6/output
``
Likewise, you can check Gizmo's progress by opening the internal log file:
``
vim $SCRATCH/hydrodynamics-benchmark/grav_R0.1_M6/GizmoLogs/RunLogs/Rad_Turb_Sphere_res32.out
``
For our default parameters in the gravitational collapse case, the simulation should output about 300 hdf5 files, and takes around 15 minutes for the entire simulation to complete.
