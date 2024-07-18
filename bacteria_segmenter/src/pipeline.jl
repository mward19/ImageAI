include("supervoxels.jl")
include("filters.jl")
include("tomoutils.jl")
include("rays.jl")
include("SVM.jl")

import .Supervoxels
import .TomoUtils
import .Filters
import .Rays
using .Rays: RayMachine
using .SVM
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

using Infiltrator

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

function feature_vectors(
        rm::RayMachine,
        sva::Supervoxels.SupervoxelAnalysis,
        N_per_vox::Integer=25
    )
    obs_points = Supervoxels.observation_points(sva.seg_dict, N_per_vox)
    
    vectors_by_supervoxel = Dict{Integer, Matrix}()
    @showprogress for key in keys(obs_points)
        features = []
        for point in obs_points[key]
            push!(features, feature_vector(rm, sva, point))
        end
        vectors_by_supervoxel[key] = hcat(features...)
    end

    return vectors_by_supervoxel
end

# TESTING
data = unit_truncate(load_object("data/run_6084.jld2")[100:200, :, :])
tomogram = Tomogram(data; downsamp_factors=[2, 2, 2])
ray_machine = RayMachine(tomogram)
@time sva = Supervoxels.SupervoxelAnalysis(tomogram.downsampled)

features = feature_vectors(ray_machine, sva)

