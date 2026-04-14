"""
Reads in a series of hdf5 files and extracts the density and temperature for
specified cells. The output is a series of numpy arrays containing the
density and temperature for each cell as a function of time.
By: Keith Poletti
"""

import os
import h5py
import numpy as np
import glob
import re
from pytreegrav import ColumnDensity as ColumnDensity
import matplotlib.pyplot as plt
from dataUtils import (
    getGasData,
    removeCellsOutsideSphere,
    getTemperature,
    getColumnDensity,
    getRadiationDensity,
)
import argparse


def main(path,mass,radius):
    """
    Main function.
    """
    rays = 12
    bands = 6  # number of radiation bands

    print("Running trace_cells")

    # create directory for outputs
    if not os.path.exists(f"output"):
        print(f"Creating directory for output")
        os.makedirs(f"output")

    # Get the list of hdf5 files
    #files = sorted(glob.glob(path + "/*.hdf5"))#sorted(glob.glob(path + "/*.hdf5"),key=os.path.getmtime)
    files = glob.glob(path + '/snapshot_*.hdf5')
    files = sorted(files, key=lambda x: int(re.search(r'snapshot_(\d+).hdf5', x).group(1)))

    # get a list of the cells to keep
    gas_data, attr = getGasData(files[0])
    units_base = {
        "UnitLength_in_cm": attr["UnitLength_In_CGS"],
        "UnitVelocity_in_cm_per_sec": attr["UnitVelocity_In_CGS"],
        "UnitMass_in_g": attr["UnitMass_In_CGS"],
    }

    print("Radiation Bands: ")
    for i in range(len(attr["Radiation_RHD_Max_Bin_Freq_in_eV"])):
        print(
            f"Band {i}: {attr['Radiation_RHD_Min_Bin_Freq_in_eV'][i]:0.2f} - {attr['Radiation_RHD_Max_Bin_Freq_in_eV'][i]:0.2f} eV"
        )    
    #if radius > 0:
    #    gas_data = removeCellsOutsideSphere(gas_data, radius)
    cells = np.unique(gas_data["ParticleIDs"])  # get the unique cell ids

    # Initialize the arrays to store the data
    time = np.zeros(len(files))
    density = np.zeros((len(files), len(cells)))
    temperature = np.zeros((len(files), len(cells)))
    radiation = np.zeros((len(files), len(cells), bands))
    column_density = np.zeros((len(files), len(cells), rays))
    velocities = np.zeros((len(files),len(cells),3))
    coordinates = np.zeros((len(files),len(cells),3))
    dust_temperature = np.zeros((len(files), len(cells)))

    max_temp = np.zeros(len(files))
    max_den = np.zeros(len(files))

    phi_ray = (1.+np.sqrt(5.))/2.
    rays = np.array(
            [
            [phi_ray,1,0],
            [-phi_ray,1,0],
            [phi_ray,-1,0],
            [-phi_ray,-1,0],
            [1,0,phi_ray],
            [-1,0,phi_ray],
            [1,0,-phi_ray],
            [-1,0,-phi_ray],
            [0,phi_ray,1],
            [0,-phi_ray,1],
            [0,phi_ray,-1],
            [0,-phi_ray,-1]
            ])
    #rays = np.random.normal(size=(12, 3))
    rays /= np.sqrt((rays * rays).sum(1))[:, None]

    for i, f in enumerate(files):
        # Get the data from the file
        gas_data, attr = getGasData(f)

        time[i] = (
            attr["Time"] 
            * units_base["UnitLength_in_cm"]
            / units_base["UnitVelocity_in_cm_per_sec"]
        ) / (
            3600 * 24 * 365 * 1e3
        )  # convert to kyr
        print(
            f"Processing file {i + 1}/{len(files)} T = {time[i]:0.3f} kyr with {gas_data['ParticleIDs'].shape[0]} cells"
        )
        if len(gas_data["Temperature"]) < len(cells):
            continue

        # Get the maximum temperature and density for each file
        max_temp[i] = np.max(gas_data["Temperature"])
        max_den[i] = np.max(gas_data["Density"])

        # Get the column density
        NH = getColumnDensity(gas_data, rays)


        #gas_data = removeCellsOutsideSphere(gas_data, radius)

        # keep only the specified cells
        index = np.squeeze(np.where(np.isin(gas_data["ParticleIDs"], cells)))
        # sort the index based on the cell id to ensure the data is in the same order
        index = index[np.argsort(gas_data["ParticleIDs"][index])]
 
        gas_data = {k: v[index] for k, v in gas_data.items()}

        # Get the temperature from the data
        temperature[i] = getTemperature(gas_data)  # [kelvin]
        density[i] = gas_data["Density"]  # [code mass]/[code length]^3
        column_density[i] = NH[index]  # [code mass]/[code length]^2
        radiation[i] = getRadiationDensity(gas_data, attr)
        # [code energy]/[code length]^3 = [code mass]/[code length]^5
        velocities[i] = gas_data['Velocities']
        coordinates[i] = gas_data['Coordinates']
        dust_temperature[i] = gas_data['Dust_Temperature']


    # Mask out time steps with cells lost to accretion
    mask = ~np.all(temperature == 0, axis=-1)
    temperature = temperature[mask,:]
    density = density[mask,:]
    column_density = column_density[mask,:]
    radiation = radiation[mask,:]
    time = time[mask]
    velocities = velocities[mask,:]
    coordinates = coordinates[mask,:]
    dust_temperature = dust_temperature[mask,:]
    max_temp = max_temp[mask]
    max_den = max_den[mask]


    # convert from code units to cgs
    density *= (
        units_base["UnitMass_in_g"] / units_base["UnitLength_in_cm"] ** 3
    )  # g/cm^3
    max_den *= (
        units_base["UnitMass_in_g"] / units_base["UnitLength_in_cm"] ** 3
    )  # g/cm^3
    #time *= (
    #    units_base["UnitLength_in_cm"] / units_base["UnitVelocity_in_cm_per_sec"]
    #)  # sec
    radiation *= (
        units_base["UnitMass_in_g"]
        * units_base["UnitVelocity_in_cm_per_sec"] ** 2
        / units_base["UnitLength_in_cm"] ** 3
    )  # erg/cm^3

    # additionally convert the column density to number density
    column_density *= (
        units_base["UnitMass_in_g"]
        / units_base["UnitLength_in_cm"] ** 2
        / (1.4 * 1.67e-24)
    )

    temp_denisty = (
        4.20
        * units_base["UnitMass_in_g"]
        / (4 / 3 * np.pi * (radius * units_base["UnitLength_in_cm"]) ** 3)
    )
    numb_density = temp_denisty / (1.4 * 1.67e-24)
    col_dens = numb_density * radius * units_base["UnitLength_in_cm"]
    print(f"Expected Number Density: {col_dens:.2e} cm^[-2])")
    print(f"Calculated Number Density: {column_density[0, 0, 3]:.2e} cm^[-2])")
    # calculate the Av
    Av = column_density / 1.6e21

    # convert sec to kyr
    # time /= 3600 * 24 * 365 * 1e3

    # convert radiation into Draines G_0 = UV/(8.94e-14)
    radiation /= 8.94e-14

    #print(f"Plotting for Cell: {cells[0]}")
    # Plot the data
    #plt.figure()
    #plt.plot(time, temperature[:, 0], label=f"Temperature {cells[0]}")
    #plt.plot(time, max_temp, label="Max Temperature")
    #plt.legend()
    #plt.title("Temperature")
    #plt.xlabel("Time (kyr)")
    #plt.ylabel("Temperature (K)")
    #plt.savefig(f"plots/{mass}/{mass}_temperature_{cells[0]}.png")
    #plt.figure()
    #plt.plot(time, density[:, 0], label=f"Density {cells[0]}")
    #plt.plot(time, max_den, label="Max Density")
    #plt.legend()
    #plt.title("Density")
    #plt.xlabel("Time (kyr)")
    #plt.ylabel("Density (g/cm^3)")
    #plt.yscale("log")
    #plt.savefig(f"plots/{mass}/{mass}_density_{cells[0]}.png")

    #plt.figure()
    #plt.plot(time, np.mean(Av[:, 0, :],axis=-1))
    #plt.title("Av Parameter")
    #plt.xlabel("Time (kyr)")
    #plt.ylabel("N_H (cm^[-2])")
    #plt.yscale("log")
    #plt.savefig(f"plots/{mass}/{mass}_Av_{cells[0]}.png")

    # create a array to store the data
    data = np.zeros((np.sum(mask), len(cells), 10 + bands))
    data[:, :, 0:3] = coordinates
    data[:, :, 3:6] = velocities
    data[:, :, 6] = density
    data[:, :, 7] = temperature
    data[:, :, 8] = dust_temperature
    data[:, :, 9] = np.mean(Av,axis=-1) #Av[..., ray_saved]
    data[:, :, 10:] = radiation
    # save the data to a numpy file
    print(f"Saving data for mass: {mass} with shape {data.shape}")
    np.save(f"output/{mass}_trace_cells.npy", data)
    np.save(f"output/{mass}_trace_cells_time.npy", time)  # save the time array


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="trace_cells.py: converts gizmo outputs to chemical network inputs")
    parser.add_argument("--gizmo_path",type=str)
    parser.add_argument("--mass",type=str)
    parser.add_argument("--radius",type=float)
    args = parser.parse_args()
    main(args.gizmo_path,args.mass,args.radius)

