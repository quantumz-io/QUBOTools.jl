const _CHIMERA_DEFAULT_CELL_SIZE = 8
const _CHIMERA_DEFAULT_PRECISION = 5

@doc raw"""
    Chimera(
        linear_terms::Dict{Int,Int}
        quadratic_terms::Dict{Tuple{Int,Int},Int}
        cell_size::Int
        precision::Int
        scale::Float64
        offset::Float64
        factor::Float64
        degree::Int
        effective_degree::Int
        coordinates::Dict{Int,Tuple{Int,Int,Int,Int}}
    )
    
The format of the instance-description file starts with a line giving the size of the Chimera graph[^chimera].
Two numbers are given to specify an ``m \times n`` rectangle, but currently only a square (``m = n``) is accepted.

The subsequent lines are of the form
```
    <Chimera vertex> <Chimera vertex> weight
```
where `<Chimera vertex>` is specified by four numbers using the format, Chimera graph, ``C_N``:
    
Vertices are ``v = (x, y, o, i)`` where
- ``x, y \in [0, N - 1]`` are the horizontal, vertical coordinates of the ``K_{4, 4}``
- ``o \in [0, 1]`` is the **orientation**: (``0 = \text{horizontally connected}``, ``1 = \text{vertically connected}``)
- ``i \in [0, 3]`` is the index within the "semi-``K_{4,4}``" or "bigvertex"
- There is an involution given by ``x \iff y``, ``o \iff 1 - o``

There is an edge from ``v_p`` to ``v_q`` if at least one of the following holds:
- ``(x_p, y_p) = (x_q, y_q) \wedge o_p \neq o_q``
- ``|x_p - x_q| = 1 \wedge y_p = y_q \wedge o_p = o_q = 0 \wedge i_p = i_q``
- ``x_p = x_q \wedge |y_p-y_q| = 1 \wedge o_p = o_q = 1 \wedge i_p = i_q``

[^chimera] [alex1770/QUBO-Chimera](https://github.com/alex1770/QUBO-Chimera)
""" struct Chimera
    linear_terms::Dict{Int,Int}
    quadratic_terms::Dict{Tuple{Int,Int},Int}
    cell_size::Int
    precision::Int
    scale::Float64
    offset::Float64
    factor::Float64
    degree::Int
    effective_degree::Int
    coordinates::Dict{Int,Tuple{Int,Int,Int,Int}}

    function Chimera(
        linear_terms::Dict{Int,Int},
        quadratic_terms::Dict{Tuple{Int,Int},Int},
        cell_size::Integer,
        precision::Integer,
        scale::Float64,
        offset::Float64,
        factor::Float64,
        degree::Integer,
        effective_degree::Integer,
        coordinates::Dict{Int,Tuple{Int,Int,Int,Int}},
    )

        return new(
            linear_terms,
            quadratic_terms,
            cell_size,
            precision,
            scale,
            offset,
            factor,
            degree,
            effective_degree,
            coordinates,
        )
    end
end

function Chimera(model::AbstractModel, fmt::HFS)
    return Chimera(model, fmt.chimera_cell_size, fmt.chimera_degree, fmt.chimera_precision)
end

function Chimera(
    model::AbstractModel,
    chimera_cell_size::Union{Integer,Nothing} = nothing,
    chimera_degree::Union{Integer,Nothing} = nothing,
    chimera_precision::Union{Integer,Nothing} = nothing,
)
    variable_set    = QUBOTools.variable_set(model)
    linear_terms    = QUBOTools.linear_terms(model)
    quadratic_terms = QUBOTools.quadratic_terms(model)
    max_variable_id = maximum(variable_set)

    if isnothing(chimera_cell_size)
        chimera_cell_size = _CHIMERA_DEFAULT_CELL_SIZE

        @warn "Assuming 'chimera_cell_size' = $(chimera_cell_size)"
    end

    min_chimera_degree = ceil(Int, sqrt(max_variable_id / chimera_cell_size))

    if isnothing(chimera_degree)
        chimera_degree = min_chimera_degree

        @warn "Assuming 'chimera_degree' = $(chimera_degree)"
    end

    if chimera_degree < min_chimera_degree
        error(
            """
            Error: 'chimera_degree' of '$(chimera_degree)' was specified.
            However, the minimum 'chimera_degree' required for a problem with a variable index as great as '$(max_variable_id)' is '$(min_chimera_degree)'.
            """,
        )
    end

    if isnothing(chimera_precision)
        chimera_precision = _CHIMERA_DEFAULT_PRECISION

        @warn "Assuming 'chimera_precision' = $(chimera_precision)"
    end

    chimera_cell_row_size = chimera_cell_size ÷ 2

    # These values are used to transform a variable index into a chimera 
    # coordinate (x,y,o,i)
    # x - chimera_row
    # y - chimera_column
    # o - chimera_cell_column - indicates the first or the second row of a chimera cell
    # i - chimera_cell_column_id - indicates ids within a chimera cell
    # Note that knowing the size of source chimera graph is essential to doing this mapping correctly 

    chimera_cell_column = Dict{Int,Int}(
        i => (i % chimera_cell_size) ÷ chimera_cell_row_size for i in variable_set
    )
    chimera_cell_column_id =
        Dict{Int,Int}(i => (i % chimera_cell_row_size) for i in variable_set)
    chimera_cell = Dict{Int,Int}(i => (i ÷ chimera_cell_size) for i in variable_set)
    chimera_row = Dict{Int,Int}(i => (j ÷ chimera_degree) for (i, j) in chimera_cell)
    chimera_column = Dict{Int,Int}(i => (j % chimera_degree) for (i, j) in chimera_cell)
    chimera_coordinates = Dict{Int,Tuple{Int,Int,Int,Int}}(
        i => (
            chimera_row[i],
            chimera_column[i],
            chimera_cell_column[i],
            chimera_cell_column_id[i],
        ) for i in variable_set
    )

    chimera_effective_degree =
        1 + max(maximum(values(chimera_row)), maximum(values(chimera_column)))

    if chimera_effective_degree > chimera_degree
        error(
            """
            The value for 'chimera_effective_degree' is greater than 'chimera_degree', which is infeasible
            """,
        )
    end

    max_abs_coeff  = maximum(abs.([collect(values(linear_terms)); collect(values(quadratic_terms))]))
    chimera_factor = 10^chimera_precision / max_abs_coeff

    chimera_linear_terms    = Dict{Int,Int}()
    chimera_quadratic_terms = Dict{Tuple{Int,Int},Int}()

    for (i, l) in linear_terms
        chimera_linear_terms[i] = round(Int, l * chimera_factor)
    end

    for ((i, j), q) in quadratic_terms
        chimera_quadratic_terms[(i, j)] = round(Int, q * chimera_factor)
    end

    chimera_scale  = scale(model) / chimera_factor
    chimera_offset = offset(model) * chimera_factor

    return Chimera(
        chimera_linear_terms,
        chimera_quadratic_terms,
        chimera_cell_size,
        chimera_precision,
        chimera_scale,
        chimera_offset,
        chimera_factor,
        chimera_degree,
        chimera_effective_degree,
        chimera_coordinates,
    )
end
