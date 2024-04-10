import os
import sys

def check_subdirectories(search_file, dir_to_search, output_file):
    """
    This function checks if any subdirectories match the directory names from a file.
    If a match is found, it writes the subdirectory name to an output file.
    """
    # Read the file and get the directory names
    with open(search_file, 'r') as file:
        directory_names = file.read().splitlines()

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