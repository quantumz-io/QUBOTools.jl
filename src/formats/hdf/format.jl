struct HDF <: AbstractFormat

    function HDF(
        dom::Union{BoolDomain,SpinDomain,Nothing} = nothing,
        sty::Nothing                              = nothing;
    )
        return new()
    end
end
domain(fmt::HDF) = fmt.domain

supports_domain(::Type{HDF}, ::BoolDomain)    = true
# supports_domain(::Type{HDF}, ::BoolDomain) = true
# supports_domain(::Type{HDF}, ::SpinDomain) = true

infer_format(::Val{:h5})                 = HDF(nothing, nothing)
# infer_format(::Val{:bool}, ::Val{:h5}) = HDF(𝔹, nothing)
# infer_format(::Val{:spin}, ::Val{:h5}) = HDF(𝕊, nothing)

include("parser.jl")
include("printer.jl")