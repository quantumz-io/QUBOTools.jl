function _write_linear(data::Dict{Int64, Float64})
    arr = zeros(length(data))
    println(data)
    for i in data
        arr[i[1]] = i[2]
    end
    return arr
end

function _write_quadratic(data::Dict{Tuple{Int64, Int64}, Float64}, size::Int)
    arr = zeros(size, size)
    println(data)
    for i in data
        arr[i[1][1], i[1][2]] = i[2]
    end

    return arr
end

function write_model(io::HDF5.File, model::AbstractModel, fmt::HDF)
    data = Dict{Symbol,Any}(
        :linear_terms    => linear_terms(model),
        :quadratic_terms => quadratic_terms(model),
        :offset          => offset(model),
        :scale           => scale(model),
        :id              => id(model),
        :version         => version(model),
        :description     => description(model),
        :metadata        => metadata(model),
        :sampleset       => sampleset(model),
    )

    linear_arr = _write_linear(data[:linear_terms])
    quadratic_arr = _write_quadratic(data[:quadratic_terms], length(data[:linear_terms]))

    qubo = create_group(io, "Qubo")
    spectrum = create_group(io, "Spectrum")
    qubo["biases"] = linear_arr
    qubo["couplings"] = quadratic_arr
    spectrum["energies"] = [0;0]
    spectrum["states"] = [0;0]
    # close(io)

    return nothing


end