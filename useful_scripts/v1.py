import subprocess
import numpy as np
import mrcfile
from PIL import Image
from matplotlib import pyplot as plt

# TODO:
# keep track of multiple motors and return transformed labels
# add more images (low)

def mod_to_csv(modfile,output_path):
# Construct the bash command
    bash_command = f"imodinfo -a {modfile} | grep '^slicerAngle' | awk '{{print $(NF-5)\",\"$(NF-4)\",\"$(NF-3)\",\"$(NF-2)\",\"$(NF-1)\",\"$NF}}' > {output_path}"

# Run the bash command
    subprocess.run(bash_command, shell=True)
    return

def normalize_image(image):
    min_value = np.min(image)
    max_value = np.max(image)
    normalized_image = ((image - min_value) / (max_value - min_value)) * 255
    return normalized_image.astype(np.uint8)

def rotate_vol(input_file,labels,thickness):
    my_labels = np.loadtxt(labels, delimiter=',')
    new_label = my_labels[:,:2]
    for i,label in enumerate(my_labels):
        with mrcfile.open(input_file) as mrc:
            z,height,width = np.shape(mrc.data)
        x_center,y_center,z_center = label[3:]
        x_rot,y_rot,z_rot = label[:3]
        pre_averaged_img = np.empty((height,width,thickness),dtype='float32')
        for j in range(thickness):
            z_true = z_center - thickness//2 + j
            output_file=input_file[:-4] + f"tomo_{i}_slice{j}.rec"
            cmd = f"rotatevol {input_file} {output_file} -size {width},{height},1 -center {x_center},{y_center},{z_true} -angles {z_rot},{y_rot},{x_rot}"
            subprocess.run(cmd, shell=True)
            with mrcfile.open(output_file) as mrc:
                pre_averaged_img[:,:,j] = mrc.data
        new_label[:,0] -= (x_center - width//2)
        new_label[:,1] -= (y_center - height//2)
        np.savetxt(f"new_label{i}.csv",new_label,delimiter=',')
        average_img = np.average(pre_averaged_img,axis=2)
        output_final = input_file[:-4] + f"tomo_{i}_averaged.rec"
        with mrcfile.new(output_final,overwrite=True) as finalmrc:
            finalmrc.set_data(average_img)
        clean_cmd = f"rm {input_file[:-4]}tomo_{i}_slice*"
        subprocess.run(clean_cmd, shell=True)



    return

def get_frames(rotated_vol,lable,num_frames,size):
    if size < 60:
        print("size is smaller than a typicall flagella motor")
        return

    my_labels = np.loadtxt(label, delimiter=',')

    for i in range(num_frames):
        with mrcfile.open(rotated_vol) as mrc:
            img = mrc.data
        height,width = np.shape(img)
        if size > width:
            print("size is greater than image")
            return
        print(np.shape(img))
        x_max = np.random.randint((width//2)+30,width//2+size)
        y_max = np.random.randint((height//2)+30,width//2+size)
        frame = img[x_max-size:x_max,y_max-size:y_max]
        # Check all labels and see if they are within size
        final_labels_index = []
        for value_x,value_y,j in enumerate(zip(my_labels[:,0],my_labels[:,1])):
            if (x_max-size <= value_x <= x_max) and (y_max-size <= value_y <= y_max):
                final_labels_index.append(i)

        np.savetxt(f"final_labels{i}.csv",my_labels[final_labels_index])

        n_frame = normalize_image(frame)
        n_frame = np.flipud(n_frame)
        im = Image.fromarray(n_frame)
        im.save(f"frame{i}.png")
    return


# mod_to_csv('fm.mod','test.csv')
rotate_vol('20120923_Hylemonella_10003_full.rec','test.csv',15)
# get_frames('20120923_Hylemonella_10003_fullbig_frame0.rec',5,256)
