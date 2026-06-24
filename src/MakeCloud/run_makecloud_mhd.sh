# Define input parameters from arguments
radius=$1 	# pc
mass=$2 	# solar masses
turb_seed=$3 	# turbulent seed
alpha_turb=$4   # virial parameter
echo "Radius: $radius"
echo "Mass: $mass"
echo "Alpha: $alpha_turb"
echo "Seed: $turb_seed"

# define the path for glass and turbulence files
glass_path=./glass_orig.npy
turb_path=./turbulence # folder where to store the turbulence files

# define save path
save_path=./output

# Remove any existing files from previous run
if [ -d "$save_path" ]; then 
	rm -r $save_path
fi
mkdir $save_path

# Define the number of particles
N=3.0e4

# run the MakeCloud program with awk
#awk -F" " '{print "python MakeCloud.py --R='$radius' --M='$mass' --N='$N' --turb_sol=0.5 --bturb=0.01 --boxsize=15 --alpha_turb=1.2 --turb_seed=42 --makebox  --glass_path='$glass_path' --turb_path='$turb_path'}' $file | bash
python MakeCloud.py 	--R=$radius \
			--M=$mass \
			--N=$N \
			--turb_sol=0.5 \
			--bturb=0.01 \
			--boxsize=15 \
			--alpha_turb=$alpha_turb \
			--turb_seed=$turb_seed \
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
        alpha=$(echo $file | awk -F"_" '{print $6}')
        # grep the turb seed from the file name
        turbSeed=$(echo $file | awk -F"_" '{print $12}')
        # remove ./ from the file name
        tmp=$(echo $file | awk -F"./" '{print $2}')
        # write the GIZMO command to the job file
        echo "ibrun -n 2 ./GIZMO ./$tmp 2 1>GizmoLogs/RunLogs/gizmoC_Seed$turbSeed.out 2>GizmoLogs/RunLogs/gizmoC_Seed$turbSeed.err & wait" >> Gizmo_jobs_file
        # grep IC file
        IC=$(grep 'InitCondFile' $file | awk -F" " '{print $2}')
        # add savepath to InitCondFile
        sed -i "s|$IC|./$IC|g" $file

        # Optional: specify total time based on turbulent crossing time
        tCross=$(grep 'TurbDrive_CoherenceTime' $file | awk -F" " '{print $2}')
        tCross=$(echo $tCross | awk '{printf "%.10f\n", $1}')
        newEndTime=$(echo "$tCross*2" | bc)
        timeMax=$(grep 'TimeMax' $file | awk -F" " '{print $2}')
        sed -i "s|$timeMax|0$newEndTime|g" $file

        # Optional: specify physical time step in years
        dtCode=$(python3 years_to_code_units.py 250)
        timeBet=$(grep 'TimeBetSnapshot' $file | awk -F" " '{print $2}')
        timeBetStat=$(grep 'TimeBetStatistics' $file | awk -F" " '{print $2}')
        sed -i "s|$timeBet|$dtCode|g" $file
        sed -i "s|$timeBetStat|$dtCode|g" $file

        
    fi
    mv -vn $file $save_path
done
