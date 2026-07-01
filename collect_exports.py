import os
import shutil
from pathlib import Path

# Inputs
phys = 'grav'
cases = ['R0.025_M6','R0.05_M6','R0.1_M6','R0.2_M6']

# Create/clear the exports directory
directory = Path("exports")
if directory.exists():
    for item in directory.iterdir():
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()
else:
    directory.mkdir(exist_ok=True)

# Loop through cases and extract outputs
for case in cases:
    case_dir = phys + '_' + case
    output_dir = case_dir + '/output'
    trace_dir = case_dir + '/trace_cells/output'

    trace_file = trace_dir + '/' + case[case.find('M'):] + '_trace_cells.npy'
    time_file = trace_dir + '/' + case[case.find('M'):] + '_trace_cells_time.npy'

    # Copy trace cells and time file
    shutil.copy(trace_file, 'exports/' + case + '_trace_cells.npy')
    shutil.copy(time_file, 'exports/' + case + '_time.npy')

    # Zip all outputs of the starforge run, including the hdf5 files
    shutil.make_archive('exports/starforge_' + case, "zip", output_dir)

    
