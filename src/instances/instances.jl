@doc raw"""
    AbstractProblem{T}
"""
abstract type AbstractProblem{T} end

@doc raw"""
    generate(::AbstractProblem, ::Domain)
"""
function generate end

include("problems/nae3sat.jl")
include("problems/sk.jl")
