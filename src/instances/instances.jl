@doc raw"""
    AbstractProblem{T}
"""
abstract type AbstractProblem{T} end

@doc raw"""
    generate(::AbstractRNG, ::AbstractProblem, ::Domain)
"""
function generate end

function generate(problem::AbstractProblem{T}, dom::Domain) where {T}
    return generate(Random.GLOBAL_RNG, problem, dom)
end

include("problems/nae3sat.jl")
include("problems/sk.jl")
include("problems/xorsat.jl")
