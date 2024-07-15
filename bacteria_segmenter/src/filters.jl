module Filters

using Images
using LocalFilters
using ImageFiltering


""" Dynamic filter for tomograms. """
# TODO. Just a placeholder for now
function filter(data)
    filtered = guided_filter(data, data, 4, 0.5)
    return guided_filter(filtered, filtered, 4, 0.5)
end

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



end # module