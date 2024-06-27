'''
CZI Data Preparation Pipeline
Author: Eben Lonsdale
Date: 27 June 2024
Dependencies: cryoet_data_portal, os, collections, sys, shutil

Description:
This script is meant to prepare annotation files from the supercomputer to be put into a depostion and uploaded to the CZI database. It takes in a search directory on the super computer,
an output directory for the files, and an annotation file to search for. It then finds matching run names between the super computer and CZI datasets, and copies the files to the 
output directory with the following naming convention: <CZI_run_name>_<CZI_run_id>_<target_file>. The files are organized by dataset ID as a subdirectory in the output directory.

Usage:
python czi_data_prep_pipeline.py -s <search_directory> -o <output_directory> -f <target_file>
This script can find the specific files, for example "MS.mod".
Show this message with -h.'''
# import necessary libraries
import os
from collections import defaultdict
import sys
import shutil
# check for non-standard depency
try:
    from cryoet_data_portal import Client, Dataset
except ImportError:
    print("Missing dependency: cryoet_data_portal. Please install it using\npip install -U cryoet-data-portal\nbefore running this script.")
    sys.exit(1)


# functions to get run names from sc and czi
def get_sc_runnames(search_dir):
    '''Get run names from super computer datasets in the search directory.'''
    sc_run_names = set()
    # search for run names in the directory
    for dirpath, dirnames, filenames in os.walk(search_dir):
        if not dirnames:
            run_name = os.path.basename(dirpath) # get the run name
            sc_run_names.add(run_name)
    return sc_run_names

def get_czi_runnames():
    '''Get updated run names for Grant Jensen's datasets from CZI.'''
    client = Client() # create a client object
    datasets = [] # list to hold dataset objects
    for dataset in Dataset.find(client):
        # get only datasets with Grant Jensen as an author
        if any(author.name == "Grant Jensen" for author in dataset.authors):
            datasets.append(dataset)
    # get CZI run names and run IDs
    czi_ids = dict() # dictionary to associate run names with run IDs
    czi_run_names = set() # array to hold run names
    for dataset in datasets:
        for run in dataset.runs:
            czi_ids[run.name] = [dataset.id,run.id] # store dataset and run IDs for later
            czi_run_names.add(run.name)
    return czi_run_names, czi_ids


# functions to find matching runs and directories
def find_matching_runs(sc_run_names, czi_run_names,czi_ids):
    """
    Finds matching run names between sc and CZI datasets.
    
    Parameters:
    - sc_run_names: A set of run names from single-cell datasets.
    - czi_run_names: A set of run names from CZI datasets.
    - czi_ids: A dictionary mapping CZI run names to their dataset and run IDs.
    
    Returns:
    - A set of matching run names.
    - A list of lists containing matching run information in the order:
      [sc_run_name, czi_run_name, czi_dataset_id, czi_run_id].
    """
    matching_run_names = set() # set to hold matching run names
    matching_run_info = dict() # list to hold matching run info
    for czi_run in czi_run_names:
        two_pattern = czi_run[0:2] + czi_run[3:] # pattern to compare our 2 letter names to CZI's 3 letter names
        if czi_run in sc_run_names:
            matching_run_names.add(czi_run)
            matching_run_info[czi_run] = [czi_run,czi_ids[czi_run][0],czi_ids[czi_run][1]] 
        elif two_pattern in sc_run_names:
            matching_run_names.add(two_pattern)
            matching_run_info[two_pattern] = [czi_run,czi_ids[czi_run][0],czi_ids[czi_run][1]]
    return matching_run_names, matching_run_info

def find_matching_directories(search_dir, matching_run_names,matching_run_info):
    """Find directories that match any of the names in 'directory_names' starting from 'search_dir'."""
    matched_dirs = list()
    matched_dirs_info = dict() # store directory info to make new file paths/names later
    for root, dirs, files in os.walk(search_dir):
        for dir_name in dirs:
            if dir_name in matching_run_names:
                full_dir = os.path.join(root, dir_name)
                matched_dirs.append(full_dir)
                matched_dirs_info[full_dir] = [matching_run_info[dir_name][0],matching_run_info[dir_name][1],matching_run_info[dir_name][2]] # get CZI runname, dataset and run ID
    return matched_dirs,matched_dirs_info

# functions to find and copy files
def find_mod_files_and_directories(matched_dirs,target_file):
    """Given a list of directories, find all target files within them and track directories."""
    target_file_dirs = defaultdict(set)
    for directory in matched_dirs:
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file == target_file:
                    target_file_dirs[file].add(root)
    return target_file_dirs

def copy_files_to_target_directories(target_file_dirs, output_dir,matched_dirs_info):
    """Copy files in 'target_file_dirs' to 'output_dir'. Also keeps track of how many files were copied.
    Files are copied with the following name convention: <CZI_run_name>_<CZI_run_id>_<target_file>.
    New file paths are created by using the dataset ID as a subdirectory in 'output_dir'."""
    file_counter = 0
    for file, directories in target_file_dirs.items():
        for dirpath in directories:
            czi_run_name, czi_dataset_id, czi_run_id = matched_dirs_info[dirpath]
            new_file_name = f"{czi_run_name}_{czi_run_id}_{file}" # create new file name with run name, run ID, and target file
            output_path = os.path.join(output_dir, str(czi_dataset_id))
            os.makedirs(output_path, exist_ok=True) # make directory if it doesn't exist
            shutil.copy(os.path.join(dirpath, file), os.path.join(output_path, new_file_name))
            file_counter += 1
    print(f"Copied {file_counter} files to {output_dir}.")

def print_help():
    """Prints help message and asks user if they want to see the full docstring."""
    print("Usage: python czi_data_prep_pipeline.py -s <search_directory> -o <output_directory> -f <target_file>")
    response = input("Would you like to read the full documentation? (y/n): ")
    if response.lower() == 'y':
        print(__doc__)
    sys.exit(0)


if __name__ == '__main__':
    # check for help flag
    if '-h' in sys.argv:
        print_help()
    # check argument length
    if len(sys.argv) != 7:
        print("Usage: python czi_data_prep_pipeline.py -s <search_directory> -o <output_directory> -f <target_file>\n For more information, use the -h flag.")
        sys.exit(1)
    
    # input variables from command line using flags
    # -s: search directory
    # -o: output directory
    # -f: target file
    # -h: help
    search_dir = sys.argv[sys.argv.index('-s')+1]
    output_dir = sys.argv[sys.argv.index('-o')+1]
    target_file = sys.argv[sys.argv.index('-f')+1] 

    # run the script
    # get run names from sc and czi
    sc_run_names = get_sc_runnames(search_dir)
    czi_run_names, czi_ids = get_czi_runnames()
    # find matching runs and directories
    matching_run_names, matching_run_info = find_matching_runs(sc_run_names, czi_run_names, czi_ids)
    matched_dirs, matched_dirs_info = find_matching_directories(search_dir, matching_run_names, matching_run_info)
    # find and copy files
    target_file_dirs = find_mod_files_and_directories(matched_dirs, target_file)
    copy_files_to_target_directories(target_file_dirs, output_dir, matched_dirs_info)