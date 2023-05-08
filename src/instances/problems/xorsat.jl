@doc raw"""
    XORSAT{T}

``r``-regular ``k``-XORSAT
"""
struct XORSAT{T} <: AbstractProblem{T}
    n::Int
    r::Int
    k::Int

    function XORSAT{T}(n::Integer, r::Integer = 3, k::Integer = 3) where {T}
        return new{T}(n, r, k)
    end
end

function generate(problem::XORSAT{T}, ::BoolDomain) where {T}

end

function generate(rng, problem::XORSAT{T}, ::SpinDomain; kws...) where {T}
    return cast(𝔹 => 𝕊, generate(rng, problem, 𝔹)...; kws...)
end

# From chook:
"""
Using row reduction, determines the number of solutions that satisfy 
the linear system of equations given by _A.X = _b mod 2.
Returns zero if no solutions exist.

"""
function find_num_solutions(_A, _b)
    A = copy(_A)
    b = copy(_b)

    M, N = size(A)

    h = 1
    k = 1

    while h <= M && k <= N
        max_i = h

        for i = h:M
            if A[i, k] == 1
                max_i = i
                break
            end
        end

        if A[max_i, k] == 0
            k += 1
        else
            if h != max_i
                A[h], A[max_i] = A[max_i], A[h]
                b[h], b[max_i] = b[max_i], b[h]
            end

            for u = (h+1):M
                flip_val = A[u, k]

                A[u] = (A[u] + flip_val * A[h]) % 2
                b[u] = (b[u] + flip_val * b[h]) % 2
            end

            h += 1
            k += 1
        end
    end

    # Find rows with all zeros
    num_all_zeros_rows = 0

    solutions_exist = true

    for i = 1:M
        if all(iszero.(A[:, i])) # All-zero row encountered
            if b[i] != 0
                solutions_exist = false
                break
            end

            num_all_zeros_rows += 1
        end
    end

    if solutions_exist
        rank = M - num_all_zeros_rows

        num_solutions = 2^(N - rank)
    else
        num_solutions = 0
    end

    return num_solutions
end

"""
Generates a r-regurlar k-XORSAT instance with n variables.

"""
function r_regular_k_xorsat(rng, n, r, k)
    idx = Vector{Int}(undef, n, k)

    while true
        for j = 1:k
            idx[:, j] .= shuffle(rng, 1:n)
        end

        for i = 1:n
            if !allunique(idx[i, :])
    end

    b = rand((0, 1), n)

    return (idx, b)
end

"""
Repetitively generates k-regular k-XORSAT problems until an instance
with non-zero solutions is obtained.
Returns the resultant XORSAT instance formulated as an
Ising minimization problem.
Also returns the ground state energy and ground state degenaracy.

"""
function plant_regular_xorsat(k, n)
    idx = nothing
    b = nothing
    A = nothing
    num_solutions = nothing

    while true
        idx, b = regular_xorsat(k, n)

        A = zeros(Int, n, n)

        for i = 1:n, j = 1:k
            A[i, idx[j]] = 1
        end

        num_solutions = find_num_solutions(A, b)

        if num_solutions != 0
            break
        end
    end

    gs_energy = -n

    bonds = []

    for i = 1:n
        push!(bonds, tuple(idx[i], (-1)^b[i]))
    end

    @show A

    return (bonds, gs_energy, num_solutions)
end
