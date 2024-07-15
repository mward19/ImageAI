module Supervoxels

using Images
using LocalFilters
using ImageFiltering
using JLD2
using Statistics
using PyCall
skimage = pyimport("skimage")

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
    return segments
end

end # module