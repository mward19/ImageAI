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
using .TomoUtils: unit_truncate
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

struct RayMachine
    lower_angles
    flat_angles
    flat_unit_vectors
    upper_angles
    all_angles
    rays_image
end

function RayMachine(tomogram::Tomogram)
    N_θ = 12
    N_γ = 3
    θ_options = LinRange(0, 2π, N_θ+1)[begin:end-1] # 2π is a duplicate of 0. Throw away
    lower_angles = [(θ, -π/12) for θ in θ_options]
    flat_angles  = [(θ, 0)     for θ in θ_options]
    upper_angles = [(θ, π/12)  for θ in θ_options]
    all_angles = vcat(lower_angles..., flat_angles..., upper_angles...)
    rays_image = Rays.Image(
        tomogram.downsampled,
        tomogram.edges,
        tomogram.gradient,
        tomogram.gradient_norm
    )

    flat_unit_vectors = []
    for (θ, γ) in flat_angles
        cos_θ = cos(θ)
        cos_γ = cos(γ)
        push!(flat_unit_vectors, [cos_θ * cos_γ, sin(θ) * cos_γ, sin(γ)])
    end
    flat_unit_vectors = hcat(flat_unit_vectors...)

    return RayMachine(
        lower_angles,
        flat_angles,
        flat_unit_vectors,
        upper_angles,
        all_angles,
        rays_image
    )
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


function supervoxelate(tomogram; slico=false)
    return Supervoxels.segment(tomogram.downsampled, 100, 1e-1; slico=slico)
end

function observation_points(tomogram, supervoxel_dict, points_per_super)
    all_points = []
    N_keys = length(keys(supervoxel_dict))
    for key in keys(supervoxel_dict)
        supervox_points = rand(supervoxel_dict[key], floor(Int, points_per_super))
        all_points = vcat(all_points..., supervox_points...)
    end
    return all_points
end

function feature_vector(tomogram::Tomogram, rm::RayMachine, pos)
    # Local properties
    intensity = tomogram.downsampled[pos...] 
    # TODO: replace intensity with histogram feature

    # Spatial properties
    # Find locations of closest contours in flat angles.
    closest_contours = hcat([Rays.closest_contour(rm.rays_image, pos, θ, γ, false) - pos
    for (θ, γ) in rm.flat_angles]...)
    # PCA to find canonical orientation # TODO: complete canonical orientation
    @infiltrate Inf in closest_contours || -Inf in closest_contours || NaN in closest_contours
    pca_model = fit(PCA, closest_contours; maxoutdim=2)
    pca_vecs = eigvecs(pca_model)
    #rays_pca = predict(pca_model, closest_contours)
    #angle_indices = angles_max_variance(rm.flat_unit_vectors, pca_vecs)
    #orientation_angles = angles_max_variance(rm.flat_unit_vectors, pca_vecs)

    offset_θ = atan(pca_vecs[3, 1], pca_vecs[2, 1])
    # TODO: Implement flipping (essentially a kind of offset_γ)
    rays_distance = []
    rays_orientation = []
    rays_norm = []
    # rays_distance_difference = [] # TODO: implement
    for (θ, γ) in rm.all_angles
        θ += offset_θ
        push!(rays_distance,    Rays.get_distance(rm.rays_image, pos, θ, γ))
        push!(rays_orientation, Rays.get_orientation(rm.rays_image, pos, θ, γ))
        push!(rays_norm,        Rays.get_norm(rm.rays_image, pos, θ, γ))
    end

    # Construct feature vector
    features = [
        intensity,
        rays_distance...,
        rays_orientation...,
        rays_norm...
    ]
end

# TESTING
data = unit_truncate(load_object("data/run_6084.jld2")[100:200, :, :])
tomogram = Tomogram(data; downsamp_factors=[2, 2, 2])
ray_machine = RayMachine(tomogram)

@time supervox_image, supervox_dict = supervoxelate(tomogram, slico=true)
@time obs_points = collect.(observation_points(tomogram, supervox_dict, 25))

@showprogress for point in obs_points
    feature_vector(tomogram, ray_machine, point)
end
