module Supervoxels

using Images
using LocalFilters
using ImageFiltering
using JLD2
using Statistics
using PyCall
skimage = pyimport("skimage")

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
Each pair in pairs is a tuple with (r, eps).
"""
function filter(data, pairs)
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

function segment(data, n_segments=100, compactness=1e-1)
    data_uint8 = UInt8.(round.(data * 255))
    segments = skimage.segmentation.slic(
        data_uint8,
        n_segments=n_segments, 
        compactness=compactness,
        max_num_iter=10,
        start_label=1,
        channel_axis=nothing
    )
    return segments
end

end # module