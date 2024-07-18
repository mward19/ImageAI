module Rays

using LinearAlgebra
using MultivariateStats

struct Image
    intensities::AbstractArray
    contours::AbstractArray{Bool}
    normalized_gradient::AbstractArray # of gradient vectors
    gradient_norm::AbstractArray
    grad_calculated::AbstractArray{Bool} # true if gradient has been calculated
    cc_memo::Dict # Memo of closest contours. Key is tuple of angle(s)
end

struct RayMachine
    lower_angles
    flat_angles
    flat_unit_vectors
    upper_angles
    all_angles
    rays_image::Image
end

function RayMachine(tomogram)
    N_θ = 12
    N_γ = 3
    θ_options = LinRange(0, 2π, N_θ+1)[begin:end-1] # 2π is a duplicate of 0. Throw away
    lower_angles = [(θ, -π/12) for θ in θ_options]
    flat_angles  = [(θ, 0)     for θ in θ_options]
    upper_angles = [(θ, π/12)  for θ in θ_options]
    all_angles = vcat(lower_angles..., flat_angles..., upper_angles...)
    rays_image = Rays.Image(
        tomogram.filtered,
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

""" Constructs an Image from intensities, contours, gradients, and gradient norms. """
function Image(
    intensities::AbstractArray, 
    contours::AbstractArray{Bool}, 
    gradient::AbstractArray{<:AbstractVector}, 
    gradient_norm::AbstractArray
)
    normalized_gradient = gradient ./ gradient_norm
    grad_calculated = trues(size(intensities))
    cc_memo = Dict{Tuple, Vector{Float64}}()
    return Image(
        intensities,
        contours,
        normalized_gradient,
        gradient_norm,
        grad_calculated,
        cc_memo
    )
end

""" Checks that a given location 𝐦 is in the bounds of `image`. """
function in_bounds(𝐈::Image, 𝐦::Vector)
    return 𝐦 == loc_in_image(𝐈, 𝐦)
end

"""
If the given point is outside the image bounds, represent the out of bounds dimensions as ∞ or -∞.
"""
function loc_in_image(𝐈::Image, 𝐦::Vector, inf_edge=true)
    𝐦 = Float64.(𝐦)
    image_dims = size(𝐈.intensities)
    @assert length(image_dims) == length(𝐦)

    for i in eachindex(image_dims)
        m_i = floor(𝐦[i])
        if m_i < 1
            𝐦[i] = inf_edge ? -Inf : 0
        elseif m_i > image_dims[i]
            𝐦[i] = inf_edge ? Inf : image_dims[i]
        end
    end
    return 𝐦
end

""" Checks if a given location 𝐦 is a contour in the image 𝐈. """
is_contour(𝐈::Image, 𝐦::Vector) = (0 != 𝐈.contours[floor.(Int, 𝐦)...])

function unit_vector(θ, γ=nothing)
    if isnothing(γ) # 2D case
        return [cos(θ), sin(θ)]
    else # 3D case
        return [sin(γ), cos(θ)*cos(γ), sin(θ)*cos(γ)]
    end
end

""" Closest contour point 𝐜. θ, γ in radians. """
function closest_contour(𝐈::Image, 𝐦::Vector, θ, γ=nothing, inf_edge=true)
    # TODO: test that this works
    if haskey(𝐈.cc_memo, (θ, γ))
        return loc_in_image(𝐈, 𝐈.cc_memo[(θ, γ)], inf_edge)
    end
    # Otherwise find it
    step = unit_vector(θ, γ) # Already normalized

    while in_bounds(𝐈, 𝐦)
        if is_contour(𝐈, 𝐦)
            return floor.(Int, 𝐦)
        end
        𝐦 += step
    end
    # If there is no contour before the edge of the image,
    # use `loc_in_image` to place ∞ values.
    cc = loc_in_image(𝐈, 𝐦, inf_edge)
    # Save and return
    𝐈.cc_memo[(θ, γ)] = loc_in_image(𝐈, 𝐦, true)
    return cc
end

""" Distance feature. """
function get_distance(𝐈::Image, 𝐦::Vector, θ, γ=nothing)
    𝐜 = closest_contour(𝐈, 𝐦, θ, γ)
    if (Inf in 𝐜) || (-Inf in 𝐜)
        return Inf
    end
    return LinearAlgebra.norm(𝐜 - 𝐦)
end

""" Orientation feature. """ # TODO: seems to have some issues. demo
function get_orientation(𝐈::Image, 𝐦::Vector, θ, γ=nothing)
    𝐜 = closest_contour(𝐈, 𝐦, θ, γ)
    if (Inf in 𝐜) || (-Inf in 𝐜)
        return NaN
    end
    return get_normalized_grad(𝐈, 𝐜) ⋅ unit_vector(θ, γ)
end

""" Norm feature. """
function get_norm(𝐈::Image, 𝐦::Vector, θ, γ=nothing)
    𝐜 = closest_contour(𝐈, 𝐦, θ, γ)
    if (Inf in 𝐜) || (-Inf in 𝐜)
        return NaN
    end
    return get_grad_norm(𝐈, 𝐜)
end

""" Distance difference feature. """
function get_dist_difference(
        𝐈 ::Image, 
        𝐦 ::Vector, 
        θ , 
        θ′, 
        γ =nothing, 
        γ′=nothing
    )
    𝐜  = closest_contour(𝐈, 𝐦, θ , γ )
    𝐜′ = closest_contour(𝐈, 𝐦, θ′, γ′)
    return (norm(𝐜 - 𝐦) - norm(𝐜′ - 𝐦)) / norm(𝐜 - 𝐦)
end

function get_normalized_grad(𝐈::Image, 𝐦::Vector)
    return 𝐈.normalized_gradient[𝐦...]
end

function get_grad_norm(𝐈::Image, 𝐦::Vector)
    return 𝐈.gradient_norm[𝐦...]
end

function get_complement(θ, γ=nothing)
    # 2D case
    if isnothing(γ)
        return θ + π/2
    end

    # 3D case
    return (θ + π/2, -γ) # Kind of an arbitrary choice. Hopefully that's okay for now
end

function feature_vector(
        rm::RayMachine,
        pos
    )
    # Spatial properties
    # Find locations of closest contours in flat angles.
    closest_contours = hcat([closest_contour(rm.rays_image, pos, θ, γ, false) - pos
                             for (θ, γ) in rm.flat_angles]...)
    # PCA to find canonical orientation # TODO: complete canonical orientation
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
    rays_dist_diff = [] # TODO: implement
    for (θ, γ) in rm.all_angles
        θ += offset_θ
        push!(rays_distance,    get_distance(rm.rays_image, pos, θ, γ))
        push!(rays_orientation, get_orientation(rm.rays_image, pos, θ, γ))
        push!(rays_norm,        get_norm(rm.rays_image, pos, θ, γ))
        θ′, γ′ = get_complement(θ, γ)
        push!(rays_dist_diff,   get_dist_difference(rm.rays_image, pos, θ, θ′, γ, γ′))
    end

    # Construct feature vector
    return [
        #rays_distance..., # distance will be misleading due to the different tomogram sizes
        rays_orientation...,
        rays_norm...,
        rays_dist_diff...
    ]
end


end # module