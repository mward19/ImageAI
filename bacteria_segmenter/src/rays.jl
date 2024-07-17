module Rays

using LinearAlgebra

struct Image
    intensities::AbstractArray
    contours::AbstractArray{Bool}
    normalized_gradient::AbstractArray # of gradient vectors
    gradient_norm::AbstractArray
    grad_calculated::AbstractArray{Bool} # true if gradient has been calculated
    cc_memo::Dict # Memo of closest contours. Key is tuple of angle(s)
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

function ray_vector(θ, γ=nothing)
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
    step = ray_vector(θ, γ) # Already normalized

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
    return get_normalized_grad(𝐈, 𝐜) ⋅ ray_vector(θ, γ)
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

end # module