import subprocess
import numpy as np
import mrcfile
import os
from PIL import Image

"""
This script is derived from create_fm_images.py, and is designed to generate images from tomograms that do not contain flagellar motors. 
It is only designed to work on tomograms with a single motor present, and will not work on tomograms with multiple motors. The script will rotate the 
tomogram to align the motor with the z-axis, and then split the tomogram into frames of a specified size, saving each frame as a .png file. 
The script will skip any tomograms that contain multiple motors.

Dependencies:
- subprocess: For executing shell commands within Python.
- numpy: Used for numerical operations, especially array manipulations.
- mrcfile: For reading and writing MRC files, which are commonly used in electron microscopy and tomography.
- PIL (Python Imaging Library): For image processing tasks, such as saving arrays as images.
- os: For navigating the file system and searching for files matching specific patterns.

Main Functions:
get_negative_frames: This function takes a rotated tomogram and a set of motor labels, and splits the tomogram into frames of a specified size,
saving each frame as a .png file. The function will skip any frames that contain the motor.

Usage: This script should run as a standalone. Make sure you update your file paths before running the script, and if needed adjust the kind of .mod files it's finding.

Author: Eben Lonsdale
Date: 1 March 2024
"""

# the following functions are taken from Braxton's create_fm_images.py
def mod_to_csv(modfile, output_path):
    try:
        bash_command = f"imodinfo -a {modfile} | grep '^slicerAngle' | awk '{{print $(NF-5),$(NF-4),$(NF-3),$(NF-2),$(NF-1),$NF}}' > {output_path}"
        subprocess.run(bash_command, shell=True, check=True)
        return True
    except subprocess.CalledProcessError:
        print(f"Failed to convert {modfile} to CSV.")
        return False

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
        cmd = f"rotatevol {input_file} {temp_output_file} -size {width},{height},{thickness} -center {x_center},{y_center},{z_center} -angles {z_rot},{y_rot},{x_rot} -v 0"
        subprocess.run(cmd, shell=True)
        with mrcfile.open(temp_output_file) as mrc:
            my_data = mrc.data
        averaged_img = np.average(my_data.astype('float32'), axis=0)
        with mrcfile.new(output_path, overwrite=True) as final_mrc:
            final_mrc.set_data(averaged_img.astype(np.float32))
        os.remove(temp_output_file)

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


def get_negative_frames(rotated_vol, labels, datadir):
    # open rec file
    with mrcfile.open(rotated_vol) as mrc:
        img = mrc.data
    height, width = img.shape
    if size > width:
        print("size is greater than image")
        return
    all_labels = np.loadtxt(labels, delimiter=' ')
    if len(all_labels) > 1:
        print("This script is currently only designed to work on tomograms with only one motor present. More than one gets tricky, sorry.")
        return

    # determine the number of splits in the x and y directions
    y_split = height // size
    x_split = width // size

    # horizontal strips = np.array_split(img, y_split, axis=0)
    # tiled_img = list()
    # for i in range(y_split):
    #     vertical_strips = np.array_split(horizontal_strips[i], x_split, axis=1)
    #     for j in range(x_split):
    #         tiled_img.append(vertical_strips[j])
    # not sure how to keep track of motor location using np.array_split

    # reshape motor labels to 2D array if necessary
    if motor_labels.ndim == 1:
        motor_labels = np.reshape(motor_labels, (1, -1))
    motor_xycoords = (all_labels[4],all_labels[5])

    # define exclusion box around flagellar motor
    exclusion_box_start = (motor_xycoords[0] - size//2, motor_xycoords[1] - size//2)
    exclusion_box_end = (motor_xycoords[0] + size//2, motor_xycoords[1] + size//2)

    # split the image into frames and save each frame as a .png file, skipping the exclusion box
    for i in range(y_split):
        for j in range(x_split):
            if (i*size < exclusion_box_start[0] or i*size > exclusion_box_end[0]) and (j*size < exclusion_box_start[1] or j*size > exclusion_box_end[1]):
                frame = img[i*size:(i+1)*size, j*size:(j+1)*size]
                n_frame = robust_normalize_image(frame)
                n_frame = np.flipud(n_frame)
                im = Image.fromarray(n_frame)
                splittxt = os.path.splittext(os.path.basename(rotated_vol))[0]
                frame_path = f"{datadir}/{splittxt}_frame_{i}_{j}.png"
                im.save(frame_path)



if __name__ == '__main__':
    main_dir = '/home/ejl62/fsl_groups/grp_tomo_db1_d2/compute/TomoDB1_d2/FlagellarMotor_P2'
    temp_dir = '/home/ejl62/fsl_groups/grp_tomo_db1_d2/eben/temp_dir'
    datadir = '/home/ejl62/fsl_groups/grp_tomo_db1_d2/eben/all_imgs'
    skipped_dirs_log_path = '/home/ejl62/fsl_groups/grp_tomo_db1_d2/braxton/skipped_dirs.txt'

    mod_files, rec_files, dir_names = find_files(main_dir)
    for i, mod_file in enumerate(mod_files):
        output_path = os.path.join(temp_dir, f"{dir_names[i]}_averaged_{i}.arec")
        
        # splittxt = os.path.splitext(os.path.basename(output_path))[0]
        # if check_frames_exist(splittxt, datadir):
        #     #print(f"Skipping {mod_file} as frames already exist in {datadir}")
        #     continue
        if not mod_to_csv(mod_file, "label.csv") or is_csv_empty("label.csv"):
            with open(skipped_dirs_log_path, 'a') as log_file:
                log_file.write(f"{dir_names[i]}\n") 
            continue  
        rotate_vol_time = time.time()
        val = new_rotate_vol(rec_files[i], "label.csv", 15, output_path, temp_dir)
        print(f'time to rotate vol: {rotate_vol_time - time.time()}')
        if val:
            continue
        subprocess.run('rm label.csv', shell=True, check=False)
        get_frames_time = time.time()
        get_negative_frames(output_path, 5, 256, datadir)
        print(f'time to get frames: {get_frames_time - time.time()}')