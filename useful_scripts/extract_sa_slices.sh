#!/bin/bash

# ---------------------------------------------------------------------------
# Script Name: extract_sa_slices.sh
# Description: extrast_sa_slices(Extract Slicer Angle Slices) takes an input MRC file, a slicer angles file, and a
#              thickness value. It rotates the MRC file based on the angles
#              provided in the slicer angles file and extracts slices of the
#              specified thickness. Currently thickness is defined as specifice z_slice to z_slice + thickness.
#
# TODO:
# Try z_center - thickness to z_center
# Try z_center - thickness/2 to z_center + thickness/2 (carful here as you wont always get integers) 
#
# Usage: ./extract_sa_slices.sh <input file> <slicer angles file> <thickness>
#
# Params:
#   <input file>         - The MRC file to be processed.
#   <slicer angles file> - A file containing the slicer angles for rotation.
#   <thickness>          - The thickness of the slices to be extracted.
#
# Dependencies:
#   - imodinfo
#   - newstack
#   - rotatevol
#   - clip
#
# Author: Braxton Owens
# Date: 2023-09-25
# ---------------------------------------------------------------------------

# Check if an input file, slicer angles file, and thickness were given
if [ $# -ne 3 ]; then
	echo "Usage: $0 <input file> <slicer angles file> <thickness>"
	exit 1
fi

# Set input file, slicer angles file, and thickness
input_file="$1"
slicer_angles_file="$2"
thickness="$3"

# Fetch slicer angles from the slicer angles file using imodinfo
slicer_angles=$(imodinfo -a "$slicer_angles_file" | grep '^slicerAngle' | awk '{print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}')

# Initialize counter
i=0

# Loop through each line of slicer angles
IFS=$'\n'
for angles in $slicer_angles; do
	# Create file names for intermediate and output files
	rotated_file="rotated_${i}.mrc"
	selected_file="selected_${i}.mrc"
	output_file="slice_${i}.mrc"

	# Parse the angles and coordinates from the slicer angles line
	IFS=' '
	my_array=($angles)
	rot_x="${my_array[0]}"
	rot_y="${my_array[1]}"
	rot_z="${my_array[2]}"
	x_center="${my_array[3]}"
	y_center="${my_array[4]}"
	z_center="${my_array[5]}"

	# Rotate the input MRC file based on the angles
	rotatevol  "$input_file" "$rotated_file" -center "$x_center,$y_center,$z_center" -angles "$rot_z,$rot_y,$rot_x"

	# Create a new stack averaging the slices
	echo "$selected_file"
	newstack -input "$rotated_file" -output "$selected_file" -secs "$((z_center-thickness/2))-$((z_center+thickness/2))"

	# Remove the rotated file
	rm "$rotated_file"

	# Average the slices in the selected stack
	clip average "$selected_file" "$output_file"

	# Remove the selected file
	rm "$selected_file"

	# Increment the counter
	i=$((i+1))
done

