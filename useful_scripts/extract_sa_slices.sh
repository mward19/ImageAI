#!/bin/bash

# Check if an input file was given and a slicer angles file was given
if [ $# -ne 3 ]; then
	echo "Usage: $0 <input file> <slicer angles file> <thickness>"
	exit 1
fi

# Set input file and slicer angles file
input_file="$1"
slicer_angles_file="$2"
thickness="$3"

slicer_angles=$(imodinfo -a "$slicer_angles_file" | grep '^slicerAngle' | awk '{print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}')

IFS=$'\n'
i=0
for angles in $slicer_angles; do
	rotated_file="rotated_${i}.mrc"
	selected_file="selected_${i}.mrc"
	output_file="slice_${i}.mrc"
	IFS=' '
	my_array=($angles)
	rot_x="${my_array[0]}"
	rot_y="${my_array[1]}"
	rot_z="${my_array[2]}"
	x_center="${my_array[3]}"
	y_center="${my_array[4]}"
	z_slice="${my_array[5]}"

	rotatevol  "$input_file" "$rotated_file" -angles "$rot_z,$rot_y,$rot_x"
	# Creates a new stack averaging the slices
	echo "$selected_file"
	newstack -input "$rotated_file" -output "$selected_file" -secs "$z_slice-$((z_slice+thickness))"
	rm "$rotated_file"
	clip average "$selected_file" "$output_file"
	rm "$selected_file"
	i=$((i+1))
done
