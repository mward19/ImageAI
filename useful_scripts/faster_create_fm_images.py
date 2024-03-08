import subprocess
import numpy as np
import mrcfile
from PIL import Image
import os
import glob

"""
This script is designed for processing and analyzing tomography data, specifically targeting flagellar motors in biological samples. It utilizes a series of image processing and analysis techniques to extract, normalize, rotate, and generate frame images from volumetric data. The script automates the extraction of angles from .mod files, normalizes and rotates volumes based on these angles, and slices the rotated volumes into 2D frame images.

Dependencies:
- subprocess: For executing shell commands within Python.
- numpy: Used for numerical operations, especially array manipulations.
- mrcfile: For reading and writing MRC files, which are commonly used in electron microscopy and tomography.
- PIL (Python Imaging Library): For image processing tasks, such as saving arrays as images.
- os, glob: For navigating the file system and searching for files matching specific patterns.

Main Functions:
- mod_to_csv(modfile, output_path): Extracts rotation angles from .mod files and saves them to a CSV file.
- robust_normalize_image(image): Normalizes image intensities to enhance contrast while avoiding outliers.
- new_rotate_vol(input_file, labels, thickness, output_path, temp_dir): Rotates volumetric data based on specified angles and extracts averaged 2D frames.
- get_frames(rotated_vol, num_frames, size, datadir): Generates and saves frame images from the rotated volume, with options for random cropping.
- find_files(root_dir): Searches a directory tree for .mod and .rec files, returning their paths along with the names of their parent directories.
- main(): Orchestrates the workflow by calling the functions defined above with appropriate arguments based on the file system structure and desired processing parameters.

Usage:
This script is intended to be run as a standalone program. Adjust the
`main_dir`, `temp_dir`, and `datadir` variables to match your file system
layout before execution. The script processes all files with pattern: "FM*.mod"
as well as the corresponding .rec files found within the `main_dir` directory, applying the described image processing and analysis techniques.

Author: Braxton Owens
Date: Feb 28 2024
"""

def mod_to_csv(modfile, output_path):
    bash_command = f"imodinfo -a {modfile} | grep '^slicerAngle' | awk '{{print $(NF-5),$(NF-4),$(NF-3),$(NF-2),$(NF-1),$NF}}' > {output_path}"
    subprocess.run(bash_command, shell=True, check=True)

def robust_normalize_image(image):
    p01, p99 = np.percentile(image, [1, 99])
    clipped_image = np.clip(image, p01, p99)
    normalized_image = ((clipped_image - p01) / (p99 - p01)) * 255
    return normalized_image.astype(np.uint8)

def new_rotate_vol(input_file, labels, thickness, output_path, temp_dir):
    my_labels = np.loadtxt(labels, delimiter=' ')
    if my_labels.ndim == 1:
        my_labels = np.reshape(my_labels, (1, -1))
    for i, label in enumerate(my_labels):
        with mrcfile.open(input_file) as mrc:
            z, height, width = mrc.data.shape
            if height > 1000:
                return True
        x_center, y_center, z_center = label[3:]
        x_rot, y_rot, z_rot = label[:3]
        temp_output_file = os.path.join(temp_dir, f"{os.path.basename(input_file)[:-4]}_tomo_{i}.rec")
        cmd = f"rotatevol {input_file} {temp_output_file} -size {width},{height},{thickness} -center {x_center},{y_center},{z_center} -angles {z_rot},{y_rot},{x_rot}"
        subprocess.run(cmd, shell=True)
        with mrcfile.open(temp_output_file) as mrc:
            my_data = mrc.data
        averaged_img = np.average(my_data.astype('float32'), axis=0)
        with mrcfile.new(output_path, overwrite=True) as final_mrc:
            final_mrc.set_data(averaged_img.astype(np.float32))
        os.remove(temp_output_file)

def get_frames(rotated_vol, num_frames, size, datadir):
    if size < 60:
        print("size is smaller than a typical flagella motor")
        return
    for i in range(num_frames):
        with mrcfile.open(rotated_vol) as mrc:
            img = mrc.data
        height, width = np.shape(img)
        if size > width:
            print("size is greater than image")
            return
        x_max = np.random.randint((width // 2) + 50, width // 2 + size)
        y_max = np.random.randint((height // 2) + 50, height // 2 + size)
        frame = img[x_max-size:x_max, y_max-size:y_max]
        n_frame = robust_normalize_image(frame)
        n_frame = np.flipud(n_frame)
        im = Image.fromarray(n_frame)
        splittxt = os.path.splitext(os.path.basename(rotated_vol))[0]
        im.save(f"{datadir}/{splittxt}_frame{i}.png")
        print(f"{datadir}/{splittxt}_frame{i}.png")
    subprocess.run(f'rm {rotated_vol}', shell=True)

def find_files(root_dir):
    mod_files = []
    rec_files = []
    dir_names = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for i,mod_file in enumerate(glob.glob(os.path.join(dirpath, 'FM*.mod'))):
            rec_file_list = glob.glob(os.path.join(dirpath, '*.rec'))
            for j,rec_file in enumerate(rec_file_list):
                mod_files.append(mod_file)
                rec_files.append(rec_file)
                path_parts = dirpath.strip(os.path.sep).split(os.path.sep)
                if len(path_parts) >= 2:
                    last_two_dirs = f'{path_parts[-2]}_{path_parts[-1]}'
                else:
                    last_two_dirs = dirpath
                dir_names.append(f'{last_two_dirs}_{i}_{j}')
    return mod_files, rec_files, dir_names

def is_csv_empty(file_path):
    try:
        return os.path.getsize(file_path) == 0
    except OSError:
        return True

import multiprocessing

def process_file(args):
    mod_file, rec_file, dir_name, temp_dir, datadir, skipped_dirs_log_path = args
    output_path = os.path.join(temp_dir, f"{dir_name}_averaged.arec")
    
    # Check if CSV is not empty, if empty, skip this iteration
    if is_csv_empty("label.csv"):
        with open(skipped_dirs_log_path, 'a') as log_file:
            log_file.write(f"{dir_name}\n")
        return
    
    # Process volume and frames
    val = new_rotate_vol(rec_file, "label.csv", 15, output_path, temp_dir)
    if not val:
        subprocess.run('rm label.csv', shell=True, check=False)
        get_frames(output_path, 5, 256, datadir)

def main():
    main_dir = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/compute/TomoDB1_d2/FlagellarMotor_P2'
    temp_dir = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/braxton/temp_dir'
    datadir = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/braxton/all_imgs'
    skipped_dirs_log_path = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/braxton/skipped_dirs.txt'

    mod_files, rec_files, dir_names = find_files(main_dir)
    pool_args = [(mod_files[i], rec_files[i], dir_names[i], temp_dir, datadir, skipped_dirs_log_path) for i in range(len(mod_files))]

    # Create a pool of workers equal to the number of available CPUs
    with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
        pool.map(process_file, pool_args)
        print(multiprocessing.cpu_count())

if __name__ == "__main__":
    main()
