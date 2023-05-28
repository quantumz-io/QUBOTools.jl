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

function _swap_rows!(x, i, j)
    x[i,:], x[j,:] .= (x[j,:], x[i,:])

    return nothing
end

function _num_solutions(A, b)
    m, n = size(A)

    # start with full rank
    rank = m

    for i in 1:m
        if iszero(A[i,:])    # all-zero row encountered
            if !iszero(b[i]) # no solutions
                return 0
            end

            rank -= 1
        end
    end

    return 2 ^ (n - rank)
end

function _mod2_elimination(_A::AbstractMatrix{U}, _b::AbstractVector{U}) where {U<:Integer}
    A = copy(_A)
    b = copy(_b)

    m, n = size(A)

    i = 1
    j = 1

    while i <= m && j <= n
        max_i = i

        for l = i:m
            if A[l, j] == 1
                max_i = l
                break
            end
        end

        if A[max_i, j] == 0
            j += 1
        else
            if i != max_i
                _swap_rows!(A, i, max_i)
                _swap_rows!(b, i, max_i)
            end

            for u in (i+1):m
                A[u,:] .⊻= A[u,j] .& A[i,:]
                b[u] ⊻= A[u,j] & b[i]
            end

            i += 1
            j += 1
        end
    end

    return (A, b)
end

"""
    k_regular_k_xorsat(rng, n, k)

Generates a ``k``-regurlar ``k``-XORSAT instance with ``n`` boolean variables.

"""
function k_regular_k_xorsat(rng, n, k)
    idx = zeros(Int, n, k)

    while true
        # generate candidate
        while true
            for j = 1:k
                idx[:, i] = np.random.permutation(n)

            if all(np.unique(row).size == k for row in indices):
                break

        b = np.random.choice(2, n)

        return indices, b

        A = zeros(Int, n, n)

        for i = 1:n, j = 1:k
            A[i, idx[j]] = 1
        end

        num_solutions = find_num_solutions(A, b)

        if num_solutions != 0
            break
        end
    end

    bonds = []

    for i = 1:n
        push!(bonds, tuple(idx[i], (-1)^b[i]))
    end

    @show A

    return (bonds, gs_energy, num_solutions)
end


"""
    r_regular_k_xorsat(rng, n, r, k)

Generates a ``r``-regurlar ``k``-XORSAT instance with ``n`` boolean variables.

If ``r = k``, then falls back to [`k_regular_k_xorsat`](@ref).
"""
function r_regular_k_xorsat(rng, n, r, k)
    if r == k
        return k_regular_k_xorsat(rng, n, k)
    else
        # This might involve Sudoku solving
        error("Method for generating generic r-regular k-XORSAT where r ≂̸ k is not implemented")
    end
end

"""
Repetitively generates k-regular k-XORSAT problems until an instance
with non-zero solutions is obtained.
Returns the resultant XORSAT instance formulated as an
Ising minimization problem.
Also returns the ground state energy and ground state degenaracy.

"""
function plant_regular_xorsat(k, n)
    
end
