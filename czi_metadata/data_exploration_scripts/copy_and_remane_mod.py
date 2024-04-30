import os
import shutil
import pandas as pd

def copy_and_rename_mod_files(source_csv, destination_dir):
    # Read the directory paths from the CSV file
    df = pd.read_csv(source_csv)
    directories = df['Directory'].tolist()

    # Create the destination directory if it does not exist
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)

    # Loop through each directory and process the .mod files
    for dir_path in directories:
        for filename in os.listdir(dir_path):
            # Check if the file is a 'MS.mod' file
            if filename == 'MS.mod':
                source_file = os.path.join(dir_path, filename)
                # Prepare new file name by prepending directory name to the file name
                new_filename = f"{os.path.basename(dir_path)}_{filename}"
                destination_file = os.path.join(destination_dir, new_filename)
                # Copy and rename the file to the new destination
                shutil.copy2(source_file, destination_file)
                print(f"Copied and renamed {source_file} to {destination_file}")

# Specify the CSV file path and the destination directory
source_csv = 'MS.mod_directories.csv'
destination_dir = 'd3_ms_rings_common'

# Run the function
copy_and_rename_mod_files(source_csv, destination_dir)

