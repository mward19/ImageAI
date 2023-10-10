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


 function make_frames(img, num_frames)
#= Function to grab random frames from ratatevol output
# input: img, num_frames
# output: set of v1 images for given tomogram =#
  motor_location_x = size(img)[1]//2;
  motor_location_y = size(img)[2]//2;

  rad_mot = 30
  cut_size = 180
  trans = cut_size//2 - rad_mot
  x_move = rand(-trans:trans);
  y_move = rand(-trans,trans);

  x_initial = (size(img)[1]//2 - cut_size)//2;
  y_initial = (size(img)[2]//2 - cut_size)//2;

  frame_x = x_initial + x_move;
  frame_y = y_initial + y_move;

  img[1] = frame_x;
  img[2] = frame_y;
  
  for i:num_frames
    frame = run()
    append!(img_list, frame)
  end
    return img_list
 end

 make_frames(rotate_volume())

 function get_files(dir)
  files = Vector{AbstractString}()
  entries = readdir(dir)

  for entry in entries
    full_path = joinpath(dir, entry)

    if isfile(full_path) && endswith(entry,[".mod", ".rec"])
      push!(files,full_path)
    end
  end
  if isempty(files)
    println("No files located in this directory")
  else 
    println("Found the following files:")
    for i in files
      println(i)
    end
  end
 end
#= Function to search through directory for required files
# input: directory
# output: .rec file , .mod file =#




 # 
