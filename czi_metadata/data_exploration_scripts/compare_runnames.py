'''
This script pulls the run names from CZI and creates a list of the matching directories on the supercomputer. It is meant to be
run in one drive at a time. The output is a csv file with the following columns:
sc_run_name: run name on the supercomputer
CZI_run_name: run name on CZI
CZI_run_id: run ID on CZI
This script also skips directories with 'figures', 'paper','MK_application', or 'PEET' in the name, as those directories do not
contain tomogram runs.

Dependencies: cryoet_data_portal, os, sys, csv
pip command to install cryoet_data_portal: pip install -U cryoet-data-portal

Author: Eben Lonsdale
Date: 24 June 2024
'''
from cryoet_data_portal import Client, Dataset
import os
import sys
import csv
# check command line arguments
if len(sys.argv) != 3:
    print("Usage: python compare_runnames.py <directory to search> <output file>")
    sys.exit(1)
# define command line arguments
dir_to_search = sys.argv[1] # directory to search
output_file = sys.argv[2] # file to save run names to

# directories that don't contain tomogram runs
words_to_skip = ['figures', 'paper','mk_application','peet']
# set to hold run names
run_names = set()
# search for run names in the directory
for dirpath, dirnames, filenames in os.walk(dir_to_search):
    # skip non-run directories
    if not any(any(word in dirpart.lower() for word in words_to_skip) for dirpart in dirpath.split(os.sep)) and not dirnames:
        # what this if statement does is break apart the directory path, make it all lowercase, and checks if any of
        # the words in words_to_skip are in the directory path. If none of the words are in the path, then it checks
        # if there are any directories in the current directory. If there are no directories, then this is hopefully a run directory
        run_name = os.path.basename(dirpath) # get the run name
        run_names.add(run_name)
    else: continue
            
# now get run names from CZI - this makes sure you get the most up to date list
client = Client()
datasets = [] # list to hold dataset objects

for dataset in Dataset.find(client):
    # get only datasets with Grant Jensen as an author
    if any(author.name == "Grant Jensen" for author in dataset.authors):
        datasets.append(dataset)

# get CZI run names and run IDs
czi_run_names_id = {} # dictionary to associate run names with run IDs
czi_run_names = [] # array to hold run names
for dataset in datasets:
    for run in dataset.runs:
        czi_run_names_id[run.name] = run.id
        czi_run_names.append(run.name)

# get overlapping run names
matching_runs = [] # list for matching run names

for run in czi_run_names:
    two_pattern = run[0:2] + run[3:] # pattern to compare our 2 letter names to CZI's 3 letter names
    if run in run_names:
        matching_runs.append([run,run,czi_run_names_id[run]]) 
    elif two_pattern in run_names:
        matching_runs.append([two_pattern,run,czi_run_names_id[run]]) 

with open(output_file, 'a', newline = '') as f1:
    writer1 = csv.writer(f1)
    # write csv header
    writer1.writerow(['sc_run_name', 'CZI_run_name','CZI_run_id'])
    # write matching runs
    writer1.writerows(matching_runs)