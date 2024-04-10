import os
'''
This script is designed to be run inside any of the 4 directories on the supercomputer to check for duplicates with
the CZI database. You have to go in a few levels for it to search correctly; the supercomputer is weird like that.

Author: Eben Lonsdale, 10 April 2024
'''

def find_duplicates(directory):
    subdirectories = {}
    duplicates = []

    for root, dirs, files in os.walk(directory):
        for dir in dirs:
            print(dir)
            path = os.path.join(root, dir)
            if dir in subdirectories:
                duplicates.append(path)
            else:
                subdirectories[dir] = path

    return duplicates

# Replace 'directory_path' with the path to your main directory
directory_path = '/home/ejl62/fsl_groups/grp_tomo_db1_d1/compute/TomoDB1_d1/FlagellarMotor_P1' # change for each directory
duplicates = find_duplicates(directory_path)

if duplicates:
    print("Duplicates found")
    # write duplicates to a txt file
    with open('duplicates.txt', 'w') as f:
        for duplicate in duplicates:
            f.write(duplicate + '\n')
            
else:
    print("No duplicates found.")