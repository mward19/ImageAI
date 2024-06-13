import os
import sys

'''
This script is designed to be run inside any of the 4 directories on the supercomputer to check for duplicates with
the CZI database. You have to go in a few levels for it to search correctly; the supercomputer is weird like that.

Author: Eben Lonsdale, 10 April 2024
'''

def check_subdirectories(search_file, dir_to_search, output_file):
    """
    This function checks if any subdirectories match the directory names from a file.
    If a match is found, it writes the subdirectory name to an output file.
    """
    # Read the file and get the directory names
    with open(search_file, 'r') as file:
        directory_names = file.read().splitlines() # file you're checking for duplicates against

    # Open the output file to write the common subdirectories
    with open(output_file, 'a') as file:
        # Check if any subdirectories match the directory names
        for dirpath, dirnames, filenames in os.walk(dir_to_search):
            for subdirectory in dirnames:
                if subdirectory in directory_names:
                    # Write the matching subdirectory to the output file
                    file.writelines(f"{subdirectory}\n")

# Check if the correct number of command line arguments are provided
if len(sys.argv) != 4:
    print("Usage: python3 search_subdirs.py <search_file> <dir_to_search> <output_file>")
else:
    # Use command line args to specify the search file, directory to search, and output file
    check_subdirectories(sys.argv[1], sys.argv[2], sys.argv[3])

## rerun with print statements, check against subdirs