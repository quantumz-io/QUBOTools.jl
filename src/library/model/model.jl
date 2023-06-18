struct VariableMap{V}
    map::Dict{V,Int}
    inv::Vector{V}

    function VariableMap{V}(
        variables::X,
    ) where {V,X<:Union{AbstractVector{V},AbstractSet{V}}}
        inv = sort!(collect(variables); lt = varlt)
        map = Dict{V,Int}(v => i for (i, v) in enumerate(inv))

        return new(map, inv)
    end
end

@doc raw"""
    Model{V,T,U} <: AbstractModel{V,T,U}

Reference [`AbstractModel`](@ref) implementation.

It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP

Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

"""
mutable struct Model{V,T,U} <: AbstractModel{V,T,U}
    # Coefficients & Factors
    form::NormalForm{T}
    # Variable Mapping
    variables::VariableMap{V}
    # Sense & Domain
    frame::Frame
    # Metadata
    metadata::Dict{String,Any}
    # Solution
    solution::SampleSet{T,U}
    # Hints
    start::Dict{Int,U}

    # Canonical Constructor
    function Model{V,T,U}(
        form::NormalForm{T},
        variables::VariableMap{V};
        sense::Union{Sense,Symbol} = :min,
        domain::Union{Domain,Symbol} = :bool,
        metadata::Union{Dict{String,Any},Nothing} = nothing,
        solution::Union{SampleSet{T,U},Nothing} = nothing,
        start::Union{Dict{Int,U},Nothing} = nothing,
    ) where {V,T,U}
        frame = Frame(sense, domain)

        if metadata === nothing
            metadata = Dict{String,Any}()
        end

        if solution === nothing
            solution = SampleSet{T,U}()
        end

        if start === nothing
            start = Dict{Int,U}()
        end

        return new{V,T,U}(form, variables, frame, metadata, solution, start)
    end

    # Empty Model
    function Model{V,T,U}(;
        scale::T = one(T),
        offset::T = zero(T),
        sense::Union{Sense,Symbol} = :min,
        domain::Union{Domain,Symbol} = :bool,
        metadata::Union{Dict{String,Any},Nothing} = nothing,
        solution::Union{SampleSet{T,U},Nothing} = nothing,
        start::Union{Dict{Int,U},Nothing} = nothing,
    ) where {V,T,U}
        form = NormalForm{T}(0, spzeros(T, 0), spzeros(T, 0, 0), scale, offset)

        variables = VariableMap{V}(V[])

        return Model{V,T,U}(form, variables; sense, domain, metadata, solution, start)
    end
end

# Dict Constructor
function Model{V,T,U}(
    linear_terms::Dict{V,T},
    quadratic_terms::Dict{Tuple{V,V},T};
    scale::T = one(T),
    offset::T = zero(T),
    kws...,
) where {V,T,U}
    # Collect Variables
    var_set = Set{V}(keys(linear_terms))

    for (i, j) in keys(quadratic_terms)
        push!(var_set, i, j)
    end

    variables = VariableMap{V}(var_set)

    # Normalize data and store it in the normal form
    n = length(var_inv)
    L = spzeros(T, n)
    Q = spzeros(T, n, n)
    α = scale
    β = offset

    for (v, l) in linear_terms
        i = variables.map[v]

        L[i] += l
    end

    for ((u, v), q) in quadratic_terms
        i = variables.map[u]
        j = variables.map[v]

        if i < j
            Q[i, j] += q
        elseif j < i
            Q[j, i] += q
        else # i == j
            L[i] += q
        end
    end

    form = NormalForm{T}(n, L, Q, α, β)

    return Model{V,T,U}(form, variables; kws...)
end

function form(model::Model; domain = QUBOTools.domain(model))
    return cast(QUBOTools.domain(model) => domain, model.form)
end

dimension(model::Model)       = dimension(form(model))
linear_terms(model::Model)    = linear_terms(form(model))
quadratic_terms(model::Model) = quadratic_terms(form(model))
scale(model::Model)           = scale(form(model))
offset(model::Model)          = offset(form(model))

frame(model::Model)  = model.frame
sense(model::Model)  = sense(frame(model))
domain(model::Model) = fomain(frame(model))

variable_map(model::Model) = model.variables.map
variable_inv(model::Model) = model.variables.inv

metadata(model::Model) = model.metadata
solution(model::Model) = model.solution

function start(model::Model, index::Integer; domain = QUBOTools.domain(model))
    if haskey(model.start, index)
        return cast(QUBOTools.domain(model) => domain, model.start[index])
    else
        return nothing
    end
end

function start(model::Model{T,V,U}; domain = QUBOTools.domain(model)) where {T,V,U}
    return Dict{Int,U}(i => start(model, i; domain) for i in keys(model.start))
end

function Base.empty!(model::Model{V,T,U}) where {V,T,U}
    model.form      = NormalForm{T}()
    model.variables = VariableMap{V}(V[])
    empty!(model.metadata)
    model.solution = SampleSet{T,U}()
    empty!(model.start)

    return model
end

function Base.isempty(model::Model)
    return iszero(dimension(model))
end

function Base.copy(model::Model{V,T,U}) where {V,T,U}
    return copy!(Model{V,T,U}(), model)
end

function Base.copy!(target::Model{V,T,U}, source::AbstractModel{V,T,U}) where {V,T,U}
    target.form      = NormalForm{T}(form(source))
    target.variables = VariableMap{V}(variables(source))
    target.frame     = frame(source)
    target.metadata  = deepcopy(metadata(source))
    target.solution  = copy(solution(source))
    target.start     = deepcopy(start(source))

    return target
end

function cast(route::Route{D}, model::Model{V,T,U}) where {D<:Domain,V,T,U}
    return Model{V,T,U}(
        cast(route, form(model)),
        model.variables;
        sense    = sense(model),
        domain   = last(route), # target
        solution = cast(route, solution(model)),
        start    = Dict{Int,U}(i => cast(route, x) for (i, x) in start(model)),
    )
end

function cast(route::Route{S}, model::Model{V,T,U}) where {S<:Sense,V,T,U}
    return Model{V,T,U}(
        cast(route, form(model)),
        model.variables;
        sense    = last(route), #target
        domain   = domain(model),
        metadata = deepcopy(metadata(model)),
        solution = cast(route, solution(model)),
        start    = deepcopy(start(model)),
    )
end