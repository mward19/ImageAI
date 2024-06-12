import mrcfile
import h5py
import numpy as np
import os

def convert_mrc_to_hdf5(mrc_filename, hdf5_filename):
    if not os.path.exists(mrc_filename):
        print(f"Error: The file {mrc_filename} does not exist.")
        return

    # Read the .mrc file
    with mrcfile.open(mrc_filename, permissive=True) as mrc:
        # Extract the voxel data
        voxel_data = mrc.data.astype(np.float32)

    # Write the data to an HDF5 file
    with h5py.File(hdf5_filename, 'w') as hdf5_file:
        hdf5_file.create_dataset('voxel_data', data=voxel_data)

    print(f"Converted {mrc_filename} to {hdf5_filename}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Convert a .mrc file to .hdf5 format.")
    parser.add_argument("mrc_filename", type=str, help="The input .mrc file path.")
    parser.add_argument("hdf5_filename", type=str, help="The output .hdf5 file path.")

    args = parser.parse_args()

    convert_mrc_to_hdf5(args.mrc_filename, args.hdf5_filename)

