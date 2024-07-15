include("supervoxels.jl")
include("filters.jl")
include("tomoutils.jl")
include("rays.jl")

import .Supervoxels
import .TomoUtils
import .Filters
import .Rays
using JLD2
using Images
using ArrayPadding
using DSP
using LinearAlgebra
using StatsBase
using .TomoUtils: display3d

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

downsample(data, factors) = TomoUtils.subsample(data, factors)

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
    
    # Use gradients to get contours with thresholding
    #percentile_threshold = 98
    #threshold = percentile(vec(gradient_norm), percentile_threshold)
    threshold = 0.002
    edges = BitArray([gradient_norm[i...] >= threshold 
                            for i in Iterators.product(axes(gradient_norm)...)])

    return Tomogram(data, downsampled, factors, filtered, gradient, gradient_norm, edges)
end


function supervoxelate(tomogram)
    return Supervoxels.segment(tomogram, 100, 1e-1; slico=false)
end

function feature_vector(tomogram, position)
    # Local properties
    intensity = tomogram.downsampled[position...]
    gradient = tomogram.gradient_norm[position...]

    # Spatial properties
    N_θ = 12
    N_γ = 3
    θ_options = LinRange(0, 2π, N_θ+1)[begin:end-1] # 2π is a duplicate of 0. Throw away
    γ_options = LinRange(-π/12, π/12, N_γ)
    rays_angles = Iterators.product(θ_options, γ_options)
    rays_image = Rays.Image(
        tomogram.downsampled,
        tomogram.edges,
        tomogram.gradient,
        tomogram.gradient_norm
    )

    # TODO: canonical orientation
    rays_distance = []
    rays_orientation = []
    rays_norm = []
    # rays_distance_difference = [] # TODO: implement
    for (θ, γ) in rays_angles
        push!(rays_distance,    Rays.get_distance(rays_image, position, θ, γ))
        push!(rays_orientation, Rays.get_orientation(rays_image, position, θ, γ))
        push!(rays_norm,        Rays.get_norm(rays_image, position, θ, γ))
    end

    # Construct feature vector
    features = [
        intensity,
        gradient,
        rays_distance...,
        rays_orientation...,
        rays_norm...
    ]
end


# TESTING
data = load_object("data/run_6084.jld2")[100:200, :, :]
tomogram = Tomogram(data; downsamp_factors=[2, 2, 2])
point = [25, 300, 300]
features = feature_vector(tomogram, point)

display3d(tomogram.edges, [point])
