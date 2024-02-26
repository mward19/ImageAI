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
    bash_command = f"imodinfo -a {modfile} | grep '^slicerAngle' | awk '{{print $(NF-5)\",\"$(NF-4)\",\"$(NF-3)\",\"$(NF-2)\",\"$(NF-1)\",\"$NF}}' > {output_path}"
    subprocess.run(bash_command, shell=True)

def robust_normalize_image(image):
    p01, p99 = np.percentile(image, [1, 99])
    clipped_image = np.clip(image, p01, p99)
    normalized_image = ((clipped_image - p01) / (p99 - p01)) * 255
    return normalized_image.astype(np.uint8)

def new_rotate_vol(input_file, labels, thickness, output_path, temp_dir):
    my_labels = np.loadtxt(labels, delimiter=',')
    if my_labels.ndim == 1:
        my_labels = np.reshape(my_labels, (1, -1))
    for i, label in enumerate(my_labels):
        with mrcfile.open(input_file) as mrc:
            z, height, width = mrc.data.shape
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
            img = mrc.data.astype(np.uint8)
        height, width = np.shape(img)
        if size > width:
            print("size is greater than image")
            return
        x_max = np.random.randint((width // 2) + 50, width // 2 + size)
        y_max = np.random.randint((height // 2) + 50, width // 2 + size)
        frame = img[x_max-size:x_max, y_max-size:y_max]
        n_frame = robust_normalize_image(frame)
        n_frame = np.flipud(n_frame)
        im = Image.fromarray(n_frame)
        splittxt = os.path.splitext(os.path.basename(rotated_vol))[0]
        im.save(f"{datadir}/{splittxt}_frame{i}.png")
    subprocess.run(f'rm {rotated_vol}', shell=True)

def find_files(root_dir):
    mod_files = []
    rec_files = []
    dir_names = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for mod_file in glob.glob(os.path.join(dirpath, 'FM*.mod')):
            rec_file_list = glob.glob(os.path.join(dirpath, '*.rec'))
            if rec_file_list:
                mod_files.append(mod_file)
                rec_files.append(rec_file_list[0])
                dir_name = os.path.basename(dirpath)
                dir_names.append(dir_name)
    return mod_files, rec_files, dir_names

def main():
    main_dir = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/compute/TomoDB1_d2/FlagellarMotor_P2'
    temp_dir = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/braxton/temp_dir'
    datadir = '/home/cbo27/fsl_groups/grp_tomo_db1_d2/braxton/all_imgs'

    mod_files, rec_files, dir_names = find_files(main_dir)

    if len(mod_files) != len(rec_files):
        print("list not the same size")
    for i, mod_file in enumerate(mod_files):
        output_path = os.path.join(temp_dir, f"{dir_names[i]}_averaged_{i}.arec")
        mod_to_csv(mod_file, "label.csv")
        new_rotate_vol(rec_files[i], "label.csv", 15, output_path, temp_dir)
        subprocess.run('rm label.csv', shell=True)
        get_frames(output_path, 5, 256, datadir)

if __name__ == "__main__":
    main()
 

