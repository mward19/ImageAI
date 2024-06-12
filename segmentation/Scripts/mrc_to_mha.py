import mrcfile
import SimpleITK as sitk
import os
import argparse
import numpy as np

def create_directory(directory_path):
    try:
        os.makedirs(directory_path, exist_ok=True)
        if not os.path.exists(directory_path):
            print(f"Directory '{directory_path}' created successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")

def convert_mrc_to_mha(mrc_file_path, output_dir):
    # Load the .mrc file
    with mrcfile.open(mrc_file_path, mode='r') as mrc:
        data = mrc.data

    # Create a MetaImage
    img = sitk.GetImageFromArray(data)

    # Ensure the output directory exists
    create_directory(output_dir)

    # Save the image
    output_file_name = os.path.splitext(os.path.basename(mrc_file_path))[0] + '.mha'
    output_file_path = os.path.join(output_dir, output_file_name)
    sitk.WriteImage(img, output_file_path)
    print(f"Converted {mrc_file_path} to {output_file_path}")

def main():
    parser = argparse.ArgumentParser(description='Convert .mrc files to .mha format.')
    parser.add_argument('mrc_file_path', type=str, help='Path to the .mrc file.')
    args = parser.parse_args()

    # Define the temporary directory
    temp_dir = "SegData"

    # Convert the .mrc file to .mha and save it in the temporary directory
    convert_mrc_to_mha(args.mrc_file_path, temp_dir)

if __name__ == "__main__":
    main()

