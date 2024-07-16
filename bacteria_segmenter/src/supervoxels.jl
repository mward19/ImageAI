module Supervoxels

using Images
using LocalFilters
using ImageFiltering
using JLD2
using Statistics
using PyCall
using Infiltrator
skimage = pyimport("skimage")

""" Returns a dictionary mapping supervoxel indices to a vector containing all pixels in that segmentation, and an array the same size as the image with supervoxel indices. """
function segment(data, n_segments=100, compactness=1e-1; slico=false)
    data_uint8 = UInt8.(round.(data * 255))
    segments = skimage.segmentation.slic(
        data_uint8,
        n_segments=n_segments, 
        compactness=compactness,
        max_num_iter=10,
        start_label=1,
        channel_axis=nothing,
        slic_zero=slico
    )
    pixels_in_seg = Dict()
    for index in Iterators.product(axes(segments)...)
        seg_val = segments[index...]
        @infiltrate length(keys(pixels_in_seg)) >= 3
        if !haskey(pixels_in_seg, seg_val)
            pixels_in_seg[seg_val] = []
        end

        push!(pixels_in_seg[seg_val], index)
    end

    return segments, pixels_in_seg
end

end # module