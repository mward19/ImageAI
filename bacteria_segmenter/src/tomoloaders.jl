module TomoLoaders

using PyCall
using JLD2
using FilePaths
using Infiltrator

sitk = pyimport("SimpleITK")

function open_mha(filepath)
    # Read the .mha file using SimpleITK (via PyCall)
    image = sitk.ReadImage(filepath)
    # Convert the image to a Julia array
    numpy_array = sitk.GetArrayFromImage(image)
    julia_array = convert(Array{Float64}, numpy_array)  # Adjust the data type as needed
    return julia_array
end

function open_mha_dir(dirpath)
    dir_files = walkdir(dirpath)
    arrays = Vector{Array}()
    for (root, dirs, files) in dir_files
        for file in files
            if file[end-3:end] != ".mha"
                continue
            end
            push!(arrays, open_mha(file))
        end
    end
    return files
end

""" Assumes files end in .mha. """
function prepare_train(tomogram_dir, segmentation_dir)
    training_sets = Vector{Tuple}() # (run_id, tomogram, segmentation)
    
    raw_dict = Dict()
    seg_dict = Dict()

    for (root, dirs, files) in walkdir(tomogram_dir)
        for file in files
            if file[end-3:end] != ".mha"
                continue
            end
            pattern = r"run_(\d+)\.mha"
            m = match(pattern, basename(file))
            id = m.captures[1]
            raw_dict[id] = root * "/" * file
        end
    end

    for (root, dirs, files) in walkdir(segmentation_dir)
        for file in files
            if file[end-3:end] != ".mha"
                continue
            end
            pattern = r"membrane_(\d+)\.mha"
            m = match(pattern, basename(file))
            id = m.captures[1]
            seg_dict[id] = root * "/" * file
        end
    end

    for key in intersect(keys(seg_dict), keys(raw_dict))
        push!(training_sets, (key, raw_dict[key], seg_dict[key]))
    end

    return training_sets
end

end # module