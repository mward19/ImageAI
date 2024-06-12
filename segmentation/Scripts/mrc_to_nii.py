import mrcfile
import nibabel as nib
import os
import argparse
import numpy as np

def convert_mrc_to_nii(mrc_file_path, output_dir):
    # Load the .mrc file
    with mrcfile.open(mrc_file_path, mode='r') as mrc:
        data = mrc.data

    # Create a NIfTI image
    img = nib.Nifti1Image(data, affine=np.eye(4))

    # Save the image
    output_file_path = os.path.join(output_dir, os.path.splitext(os.path.basename(mrc_file_path))[0] + '.nii')
    nib.save(img, output_file_path)

def main():
    parser = argparse.ArgumentParser(description='Convert .mrc files to .nii format.')
    parser.add_argument('mrc_file_path', type=str, help='Path to the .mrc file.')
    parser.add_argument('output_dir', type=str, help='Directory to save the output .nii file.')
    args = parser.parse_args()

    convert_mrc_to_nii(args.mrc_file_path, args.output_dir)

if __name__ == "__main__":
    main()

