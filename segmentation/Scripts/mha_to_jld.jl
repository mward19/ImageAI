using PyCall
using JLD2
using FilePaths

# Load the Python module for SimpleITK
sitk = pyimport("SimpleITK")

function convert_mha_to_julia(input_file::String)
    # Get the directory of the input file
    input_dir = dirname(input_file)

    # Extract the file name without extension
    file_name = basename(input_file)
    # Remove the .mha extension
    file_name = replace(file_name, ".mha" => "")

    # Construct the output file path with the same directory and new extension
    output_file = file_name * ".jld2"
    output_path = joinpath(input_dir, output_file)

    # Read the .mha file using SimpleITK (via PyCall)
    image = sitk.ReadImage(input_file)

    # Convert the image to a Julia array
    numpy_array = sitk.GetArrayFromImage(image)
    julia_array = convert(Array{Float64}, numpy_array)  # Adjust the data type as needed

    # Save the Julia array to a .jld2 file
    JLD2.save(output_path, "data", julia_array)
    println("Julia array saved to $output_path")
end

# Usage
if length(ARGS) != 1
    println("Usage: julia script.jl <input_file.mha>")
    exit(1)
end

input_file = ARGS[1]
convert_mha_to_julia(input_file)

