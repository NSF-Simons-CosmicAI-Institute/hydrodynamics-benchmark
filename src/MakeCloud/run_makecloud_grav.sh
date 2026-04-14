#!/bin/bash

# Activate virtual environment
source $SCRATCH/py-envs/makeCloud/bin/activate
export PYTHONPATH=$SCRATCH/py-envs/makeCloud/lib/python3.9/site-packages/

# Define input parameters from arguments
radius=$1 	# pc
mass=$2 	# solar masses

echo "Radius: $radius"
echo "Mass: $mass"

# define the path for glass and turbulence files
glass_path=/scratch1/10386/lsmith9003/scripts_grav/MakeCloud/glass_orig.npy
turb_path=/scratch1/10386/lsmith9003/scripts_grav/MakeCloud/turbulence # folder where to store the turbulence files

# define save path
save_path=/scratch1/10386/lsmith9003/scripts_grav/MakeCloud/output

# Remove any existing files from previous run
if [ -d "$save_path" ]; then 
	rm -r $save_path
fi
mkdir $save_path

# Define the number of particles
N=10000

# run the MakeCloud program with awk
#awk -F" " '{print "python MakeCloud.py --R='$radius' --M='$mass' --N='$N' --turb_sol=0.5 --bturb=0.01 --boxsize=15 --alpha_turb=1.2 --turb_seed=42 --makebox  --glass_path='$glass_path' --turb_path='$turb_path'}' $file | bash
python MakeCloud.py 	--R=$radius \
			--M=$mass \
			--N=$N \
			--bturb=0 \
			--alpha_turb=0 \
			--bfixed=0 \
			--spin=0 \
			--nsnap=300 \
			--tmax=1 \
			--glass_path=$glass_path \
			--turb_path=$turb_path

# find all the files that were just created
files=$(find . -name "*R${radius}*")

# move the files to the save path
for file in $files
do
    # check if the file is a text file
    if [[ $file == *.txt ]]
    then
        # grep the name of the output directory
        dir=$(grep 'OutputDir' $file | awk -F" " '{print $2}')
        # check if the directory exists
        mkdir -p $dir
        # grep the mass from the file name
        mass=$(echo $file | awk -F"_" '{print $2}')
        # remove ./ from the file name
        tmp=$(echo $file | awk -F"./" '{print $2}')
        # write the GIZMO command to the job file
        #echo "ibrun -n 2 ./GIZMO ./$tmp 2 1>GizmoLogs/RunLogs/gizmoC_Seed$turbSeed.out 2>GizmoLogs/RunLogs/gizmoC_Seed$turbSeed.err & wait" >> Gizmo_jobs_file
        # grep IC file
        IC=$(grep 'InitCondFile' $file | awk -F" " '{print $2}')
        # add savepath to InitCondFile
        sed -i "s|$IC|./$IC|g" $file
#
#        # # replace the random number
#        sed -i "s|TurbDrive_RandomNumberSeed          42|TurbDrive_RandomNumberSeed          $NewTurbSeed|g" $file
#        # # find the time between snapshots
#        # timeBetween=$(grep 'TimeBetSnapshot' $file | awk -F" " '{print $2}')
#        # exp=$(($(echo $timeBetween | cut -d 'e' -f2)*1))
#        # # increase by a factor of 10
#        # exp=$(($exp+1))
#        # exp=$(printf e%03d $exp)
#        # # recombine the number
#        # newTimeBet=$(echo $timeBetween | cut -d 'e' -f1)$exp
#        # # replace the time between snapshots
#        # sed -i "s|$timeBetween|$newTimeBet|g" $file
#
        # find the crossing time
        #tCross=$(grep 'TurbDrive_CoherenceTime' $file | awk -F" " '{print $2}')
        #tCross=$(echo $tCross | awk '{printf "%.10f\n", $1}')
	
	# Correct by a factor of 2
        #tCross=$(echo "$tCross * 2" | bc)
        # define the new end time
        #newEndTime=$(echo "$tCross * 10" | bc)
        # find max time
        #timeMax=$(grep 'TimeMax' $file | awk -F" " '{print $2}')
        # replace the end time
        #sed -i "s|$timeMax|0$newEndTime|g" $file
    fi
    mv -vn $file $save_path
done

# Clean up path and environment
deactivate
