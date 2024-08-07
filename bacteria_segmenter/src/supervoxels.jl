module Supervoxels

using Graphs
using LinearAlgebra
using Statistics
using PyCall
skimage = pyimport("skimage")

struct SupervoxelAnalysis
    intensities::AbstractArray
    seg_array::AbstractArray
    seg_dict::Dict
    seg_graph::Graph
    histograms::Dict
end

function SupervoxelAnalysis(intensities::AbstractArray; histogram_edges=LinRange(0, 1, 11))
    seg_array, seg_dict = segment(intensities, 600)
    seg_graph = construct_graph(seg_array, seg_dict)
    histograms = supervoxel_histograms(intensities, seg_dict, histogram_edges)
    return SupervoxelAnalysis(
        intensities,
        seg_array,
        seg_dict,
        seg_graph,
        histograms
    )
end


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

        if !haskey(pixels_in_seg, seg_val)
            pixels_in_seg[seg_val] = []
        end

        push!(pixels_in_seg[seg_val], collect(index))
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

function supervoxel_histograms(intensities, supervoxel_dict, edges)
    histograms = Dict()
    for key in keys(supervoxel_dict)
        histogram = zeros(length(edges)-1)
        for voxel in supervoxel_dict[key]
            intensity = intensities[voxel...]
            for edge_index in axes(edges[begin:end-1], 1)
                if intensity >= edges[edge_index] && intensity < edges[edge_index+1]
                    histogram[edge_index] += 1
                    break
                end
            end
        end

        histograms[key] = normalize(histogram)
    end

    return histograms
end


""" Returns a dictionary mapping a supervoxel index to a vector of points to sample. """
function observation_points(supervoxel_dict, points_per_supervoxel)
    all_points = Dict{Integer, Vector}()
    N_keys = length(keys(supervoxel_dict))
    for key in keys(supervoxel_dict)
        supervoxel_points = rand(supervoxel_dict[key], floor(Int, points_per_supervoxel))
        all_points[key] = supervoxel_points
    end
    return all_points
end

""" Returns the approximate centroids of each supervoxel. """
function centroids(supervoxel_dict)
    centroid_dict = Dict()
    for key in keys(supervoxel_dict)
        points = supervoxel_dict[key]
        N_sample = 100
        sample_points = rand(points, N_sample)
        centroid = mean(sample_points)
        centroid_dict[key] = floor.(Int, centroid)
    end
    return centroid_dict
end

""" Returns a dictionary mapping supervoxel indices to their labels. """
function classes(supervoxel_analyzer::SupervoxelAnalysis, segmentation_array)
    supervoxel_dict = supervoxel_analyzer.seg_dict
    class_dict = Dict()
    centroid_dict = centroids(supervoxel_dict)
    for key in keys(supervoxel_dict)
        centroid = centroid_dict[key]
        class = segmentation_array[centroid...]
        class_dict[key] = class
    end
    return class_dict
end



end # module