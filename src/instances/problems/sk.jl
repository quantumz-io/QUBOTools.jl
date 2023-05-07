@doc raw"""
    SK{T,R}

Sherrington-Kirkpatrick Model
"""
struct SK{T} <: AbstractProblem{T}
    n::Int

    function SK{T}(n::Integer) where {T}
        return new{T}(n)
    end
end

function generate(problem::SK{T}, ::SpinDomain) where {T}
    n = problem.n # number of variables

    # Ising Interactions
    h = Dict{Int,T}()
    J = Dict{Tuple{Int,Int},T}()

    for i = 1:n, j = (i+1):n
        J[(i,j)] = randn(T)
    end

    α = one(T)
    β = zero(T)

    return (h, J, α, β)
end
