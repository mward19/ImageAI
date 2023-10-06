function rotate_volume(input_file, output_file, size, center, angles)
  cmd = rotatevol $input_file $output_file -size $size -center $center -angles $angles

  run(cmd)
end


function get_labels()
  
#=   Function to get label information using imodinfo 
# input: .mod file
# output: xyz_centers, xyz_angles =#

slicer_angles=$(imodinfo -a "$slicer_angles_file" | grep '^slicerAngle' | awk '{print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}')

 end


 function make_frames()
#= Function to grab random frames from ratatevol output
# input: img, num_frames
# output: set of v1 images for given tomogram =#

 end


 function get_files()
#= Function to search through directory for required files
# input: directory
# output: .rec file , .mod file =#


 end



 # 
