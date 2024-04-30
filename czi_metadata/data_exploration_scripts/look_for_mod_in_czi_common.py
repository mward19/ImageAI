import os
import pandas as pd
from collections import Counter, defaultdict
import matplotlib.pyplot as plt

def find_matching_directories(root_path, directory_names):
    """Find directories that match any of the names in 'directory_names' starting from 'root_path'."""
    matched_directories = []
    for root, dirs, files in os.walk(root_path):
        for dir_name in dirs:
            if dir_name in directory_names:
                matched_directories.append(os.path.join(root, dir_name))
    return matched_directories

def find_mod_files_and_directories(directories):
    """Given a list of directories, find all .mod files within them and track directories."""
    mod_files = Counter()
    directories_for_files = defaultdict(set)
    for directory in directories:
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.mod'):
                    mod_files[file] += 1
                    directories_for_files[file].add(root)
    return mod_files, directories_for_files

def plot_histogram(file_counts):
    """Plot a histogram from a Counter of file occurrences."""
    labels, values = zip(*file_counts.items())
    indexes = range(len(labels))
    plt.figure(figsize=(12, 8))
    plt.bar(indexes, values, align='center', color='blue', alpha=0.7)
    plt.xticks(indexes, labels, rotation='vertical')
    plt.title('Histogram of .mod File Counts by File Name')
    plt.xlabel('File Names')
    plt.ylabel('Counts')
    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.tight_layout()  # Adjust layout to make room for rotated x-axis labels
    plt.savefig('mod_file_histogram_by_name.png', format='png', dpi=300)
    plt.show()

# Read the directory names from the CSV
df = pd.read_csv('czi_overlap_d1.csv')
directory_names = set(df['runs'].values)  # Convert to set for faster lookup

# Main variables
root_search_path = "../compute/TomoDB1_d1"

# Process
matched_dirs = find_matching_directories(root_search_path, directory_names)
mod_files_counts, directories_for_files = find_mod_files_and_directories(matched_dirs)

# Plotting
plot_histogram(mod_files_counts)


view_only = True
if view_only == False:
    # Save directories containing a specific .mod file to CSV
    target_mod_file = 'MS.mod'
    if target_mod_file in directories_for_files:
        directory_list = list(directories_for_files[target_mod_file])
        df_directories = pd.DataFrame(directory_list, columns=['Directory'])
        df_directories.to_csv(f'{target_mod_file}_directories.csv', index=False)
        print(f"Directories containing {target_mod_file} have been saved to {target_mod_file}_directories.csv.")
    else:
        print(f"No directories found containing {target_mod_file}.")

