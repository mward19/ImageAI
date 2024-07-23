module Filters

using Images
using LocalFilters
using ImageFiltering

""" Guided filtering, arbitrary dimension. """
function guided_filter(I, p, r, eps)
    kernel_dims = [2r+1 for dim in 1:ndims(I)]
    mean_kernel = ones(kernel_dims...) / ((2r+1) ^ ndims(I))
    mean(data) = imfilter(data, mean_kernel)

    mean_I =  mean(I)
    mean_p =  mean(p)
    corr_I =  mean(I .* I)
    corr_Ip = mean(I .* p)

    var_I = corr_I .- mean_I .* mean_I
    cov_Ip = corr_Ip .- mean_I .* mean_p

    a = cov_Ip ./ (var_I .+ eps)
    b = mean_p .- a .* mean_I

    mean_a = mean(a)
    mean_b = mean(b)

    q = mean_a .* I .+ mean_b
    return q
end

"""
Does multiple passes of an edge-preserving guided filter.
Each pair in the vector pairs is a tuple with (r, eps).
"""
function guided_filters(data, pairs)
    if !(typeof(pairs) <: AbstractVector)
        pairs = [pairs]
    end
    filters = [image -> guided_filter(image, image, p[1], p[2]) 
                for p in pairs]
    filtered = data
    for f in filters
        filtered = f(filtered)
    end
    return filtered
end

""" Anisotropic diffusion filter for N dimensional grayscale images. """
function anisotropic_diff_filter(data)
    data_in = Float32.(data)
    data_out = Array{Float32}(undef, size(data_in)...)
    # TODO
end


using Images
using ImageEdgeDetection
using ImageEdgeDetection: Percentile
using ImageContrastAdjustment
using Metrics

""" Guided filtering, arbitrary dimension. """
function guided_filter(I, p, r, eps)
    kernel_dims = [2r+1 for dim in 1:ndims(I)]
    mean_kernel = ones(Int.(kernel_dims)...) / ((2r+1) ^ ndims(I))
    mean(data) = imfilter(data, mean_kernel)

    mean_I =  mean(I)
    mean_p =  mean(p)
    corr_I =  mean(I .* I)
    corr_Ip = mean(I .* p)

    var_I = corr_I .- mean_I .* mean_I
    cov_Ip = corr_Ip .- mean_I .* mean_p

    a = cov_Ip ./ (var_I .+ eps)
    b = mean_p .- a .* mean_I

    mean_a = mean(a)
    mean_b = mean(b)

    q = mean_a .* I .+ mean_b
    return q
end

function rescale(array)
    global_min = min(array...)
    global_max = max(array...)
    return (array .- global_min) ./ (global_max - global_min)
end

function score(segmentation::AbstractArray, filtered::AbstractArray)
    true_gradients = imgradients(segmentation, KernelFactors.ando3)
    true_edges = BitArray(undef, size(true_gradients[begin])...)
    for i in Iterators.product(axes(true_gradients[begin])...)
        true_edges[i...] = +([abs(g[i...]) for g in true_gradients]...) > 0
    end

    alg = Canny(spatial_scale=1, high=Percentile(80), low=Percentile(20))
    filt_edges = detect_edges(img, alg)

    score = f_score(true_edges, filt_edges, beta=0.5)
    return score
end

# Input criteria: max, min, dimensions
function filter(data::AbstractArray)
    xdim, ydim = size(data)[end-1:end]
    layers = ndims(data) == 3 ? size(data, 1) : nothing

    # Put between 0 and 1
    filtered = Float64.(rescale(data))
    # Histogram equalization (for even contrast)
    filtered = adjust_histogram(filtered, Equalization(nbins=256))
    # Gaussian smoothing to reduce noise
    gauss_rad = floor(Int, max(1, max(xdim, ydim) / 75)) # TODO: dynamic. not as important
    filtered = imfilter(filtered, Kernel.gaussian((gauss_rad, gauss_rad, gauss_rad)))
    # Edge-preserving smoothing (to get rid of distracting junk)
    #@infiltrate
    rad = floor(Int, min(max(xdim, ydim) / 40, 5)) # TODO: dynamic. not as important
    filtered = guided_filter(filtered, filtered, rad, 0.05) # TODO: make 0.05 dynamic. Also big rad is expensive

    return filtered
end
    
end # module

module Tst
using ..Filters
using JLD2
using Images

include("tomoutils.jl")
using .TomoUtils

include("tomoloaders.jl")
using .TomoLoaders

data = downsample(TomoLoaders.open_mha("data/segmentation_data/raw_tomograms/dataset_10084/run_6074.mha")[150:160, :, :], (2,1,1))
display(Gray.(Filters.rescale(data[5, :, :])))
filtered = Filters.filter(data)
display(Gray.(filtered)[5,:,:])
end # module Tst