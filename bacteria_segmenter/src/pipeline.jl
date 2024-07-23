module Pipeline

include("supervoxels.jl")
include("filters.jl")
include("tomoutils.jl")
include("rays.jl")
include("SVM.jl")
include("tomoloaders.jl")

import .Supervoxels
import .TomoUtils
import .Filters
import .Rays
using .Rays: RayMachine
using .SVM
using .TomoLoaders
using JLD2
using Images
using ArrayPadding
using LinearAlgebra
using StatsBase
using .TomoUtils: display3d
using .TomoUtils: unit_truncate
using .TomoUtils: downsample
using MultivariateStats
using ProgressMeter

using PyCall
sitk = pyimport("SimpleITK")

function open_mha(filepath)
    # Read the .mha file using SimpleITK (via PyCall)
    image = sitk.ReadImage(filepath)
    # Convert the image to a Julia array
    numpy_array = sitk.GetArrayFromImage(image)
    julia_array = convert(Array{Float64}, numpy_array)  # Adjust the data type as needed
    return julia_array
end


struct Tomogram
    raw_data
    downsampled
    factors_downsample
    filtered # From downsampled
    gradient # From downsampled
    gradient_norm
    edges    # From downsampled
end

function Tomogram(data::AbstractArray; downsamp_factors=[2, 4, 4])
    factors = downsamp_factors
    downsampled = downsample(data, factors)
    filtered = Filters.filter(downsampled)
    # Calculate gradients
    intensities = filtered # Alias, for clarity
    gradient_by_dim = imgradients(intensities, KernelFactors.ando3, "reflect")
    gradient = [
        [gradient[𝐦...] for gradient in gradient_by_dim]
        for 𝐦 in Iterators.product(axes(intensities)...)
    ]
    gradient_norm = norm.(gradient)
    grad_calculated = trues(size(gradient))
    
    threshold = 0.002
    edges = BitArray([gradient_norm[i...] >= threshold 
                            for i in Iterators.product(axes(gradient_norm)...)])

    return Tomogram(data, downsampled, factors, filtered, gradient, gradient_norm, edges)
end

struct Segmentation
    raw_data
    downsampled
    factors_downsample
end

function Segmentation(raw_data; downsamp_factors=[2, 4, 4])
    factors = downsamp_factors
    downsampled = downsample(raw_data, factors)
    return Segmentation(
        raw_data,
        downsampled,
        factors
    )
end

function feature_vector(
        rm::RayMachine,
        sva::Supervoxels.SupervoxelAnalysis,
        pos
    )
    # Local properties
    supervoxel_index = sva.seg_array[pos...]
    histogram = sva.histograms[supervoxel_index]

    # Ray features
    ray_vector = Rays.feature_vector(rm, pos)

    return [
        histogram...,
        ray_vector...
    ]
end

""" Returns a dictionary mapping supervoxel indices to matrices of feature vectors. """
function feature_vectors(
        rm::RayMachine,
        sva::Supervoxels.SupervoxelAnalysis,
        N_per_vox::Integer=25
    )
    obs_points = Supervoxels.observation_points(sva.seg_dict, N_per_vox)
    
    vectors_by_supervoxel = Dict{Integer, Matrix}()
    @showprogress desc="Calculating feature vectors..." for key in keys(obs_points)
        features = []
        for point in obs_points[key]
            push!(features, feature_vector(rm, sva, point))
        end
        vectors_by_supervoxel[key] = hcat(features...)
    end

    return vectors_by_supervoxel
end

end # module

using .Pipeline

# TESTING
raw_dir = "data/segmentation_data/raw_tomograms"
seg_dir = "data/segmentation_data/annotations"

filepaths = TomoLoaders.prepare_train(raw_dir, seg_dir)

feature_matrix = nothing
classes_vector = nothing 
for (id, raw_file, seg_file) in filepaths
    indices = (100:130, 300:350, 300:350)
    # TODO: determine begin and end of missing wedges
    println(raw_file)
    data = unit_truncate(open_mha(raw_file))[indices...]
    seg = open_mha(seg_file)[indices...]

    # TODO: Make downsampling dynamic
    downsamp_factors = [2, 4, 4] 
    tomogram = Tomogram(data; downsamp_factors=downsamp_factors) 
    segmentation = Segmentation(seg; downsamp_factors=downsamp_factors)
    ray_machine = RayMachine(tomogram)
    sva = Supervoxels.SupervoxelAnalysis(tomogram.filtered)

    features_dict = feature_vectors(ray_machine, sva)
    classes_dict = Supervoxels.classes(sva, segmentation.downsampled)

    all_keys = collect(keys(features_dict))
    if isnothing(feature_matrix) && isnothing(classes_vector)
        global feature_matrix = hcat([features_dict[k] for k in all_keys]...)
        global classes_vector = vcat([fill(classes_dict[k], size(features_dict[k])[2]) 
                                      for k in all_keys]...)
    else
        this_feature_matrix = hcat([features_dict[k] for k in all_keys]...)
        this_classes_vector = vcat([fill(classes_dict[k], size(features_dict[k])[2]) 
                                    for k in all_keys]...)
        feature_matrix = hcat(feature_matrix, this_feature_matrix)
        classes_vector = vcat(classes_vector, this_classes_vector)
    end
end

save_object("features_initial.jld2", feature_matrix)
save_object("classes_initial.jld2", classes_vector)