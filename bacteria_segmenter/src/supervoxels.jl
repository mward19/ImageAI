module Supervoxels

using Images
using LocalFilters
using ImageFiltering
using JLD2
using Statistics
using Graphs
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

function in_bounds(array, indices)
    for (range, index) in zip(axes(array), indices)
        if !checkindex(Bool, range, index)
            return false
        end
    end
    return true
end

function construct_graph(supervoxel_array, supervoxel_dict)
    # Get unique labels
    labels = keys(supervoxel_dict)
    graph = Graph()
    add_vertices!(graph, length(labels))

    edges = Set{Tuple}()
    for index in Iterators.product(axes(supervoxel_array)...)
        # Check down, right, and in for potential edges
        for dim in 1:ndims(supervoxel_array)
            offset = zeros(Int, ndims(supervoxel_array))
            offset[dim] = 1

            # Ensure that the offset position is in bounds
            if !in_bounds(supervoxel_array, index .+ offset)
                continue
            end

            label_1 = supervoxel_array[index...]
            label_2 = supervoxel_array[(index .+ offset)...]
            # If the labels are different, add an edge to the graph. (Rejects duplicates)
            if label_1 != label_2
                add_edge!(graph, label_1, label_2)
            end
        end
    end

    return graph
end

end # module