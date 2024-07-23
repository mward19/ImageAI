module TomoUtils
export display3d, supervoxels_RGB, rescale, unit_truncate, downsample, upsample

using Images

function display3d(orig_data, points=[]; rad=3, interval=1, colors=[RGB(1,0,0)])
    data = RGB.(orig_data)
    Δ = rad
    for slice_index in axes(data, 1)
        if slice_index % interval != 0
            continue
        end
        for (p_index, p) in enumerate(points)
            if p[1] == slice_index
                for index in Iterators.product(p[1]-Δ:p[1]+Δ, p[2]-Δ:p[2]+Δ, p[3]-Δ:p[3]+Δ)
                    if !in_bounds(data, index)   continue   end
                    data[index...] = colors[begin + (p_index-1) % length(colors)]
                end
            end
        end
        display(data[slice_index, :, :])
    end
end

function in_bounds(array, indices)
    for (range, index) in zip(axes(array), indices)
        if !checkindex(Bool, range, index)
            return false
        end
    end
    return true
end

function supervoxels_RGB(segments, n_segments=nothing)
    if isnothing(n_segments)
        n_segments = length(unique(vec(segments)))
    end
    rand_colors = Dict([grayval => RGB(rand(), rand(), rand()) for grayval in 1:n_segments])
    segments_display = Array{RGB}(undef, size(segments)...)
    for i in Iterators.product(axes(segments)...)
        segments_display[i...] = rand_colors[segments[i...]]
    end

    return segments_display
end


function rescale(array)
    global_min = min(array...)
    global_max = max(array...)
    return (array .- global_min) ./ (global_max - global_min)
end

function unit_truncate(val::Real)
    if val < 0   return 0.   end
    if val > 1   return 1.   end
    return val
end

function unit_truncate(array::AbstractArray)
    return unit_truncate.(array)
end

""" Downsample array by `factors`. """
function downsample(array, factors::Tuple)
    if length(factors) != ndims(array)
        throw(
            ErrorException("Each element of factors should correspond to an axis of the array.")
        )
    end

    original_dims = size(array)
    new_dims = floor.(Int, original_dims ./ factors)
    return imresize(array, new_dims)
end

""" Approximate inverse of downsample. """
function upsample(array, factors::Tuple)
    if length(factors) != ndims(array)
        throw(
            ErrorException("Each element of factors should correspond to an axis of the array.")
        )
    end

    original_dims = size(array)
    new_dims = floor.(Int, original_dims .* factors)
    return imresize(array, new_dims)
end

end # module