import SimpleITK as sitk
import numpy as np
import sys

def convert_mha_to_numpy(file_path, output_path):
    # Read the .mha file using SimpleITK
    image = sitk.ReadImage(file_path)

    # Convert the image to a numpy array
    numpy_array = sitk.GetArrayFromImage(image)

    # Save the numpy array to a .npy file
    np.save(output_path, numpy_array)

# Usage
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <path_to_file.mha> <output_path.npy>")
        sys.exit(1)

    file_path = sys.argv[1]
    output_path = sys.argv[2]
    convert_mha_to_numpy(file_path, output_path)
    print(f"Numpy array saved to {output_path}")

