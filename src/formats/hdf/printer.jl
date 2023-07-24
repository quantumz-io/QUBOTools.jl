
function _write_linear(io::IO)
    arr = zeros(length(io))
    for i in io
        arr[i[1]] = i[2]
    end
    return arr
end

function _write_quadratic(io::IO, size::Int)
    arr = zeros(size, size)
    for i in io
        arr[i[1][1], i[1][2]] = i[2]
    end

    return arr
end

function write_model(io::IO, model::AbstractModel, fmt::HDF)
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

    file = h5open(io, "w")
    linear_arr = _write_linear(data[:linear_terms])
    quadratic_arr = _write_quadratic(data[:quadratic_terms], length(data[:linear_terms]))

    path = io
    file = h5open(path, "w")
    qubo = create_group(file, "Qubo")
    spectrum = create_group(file, "Spectrum")
    qubo["biases"] = linear_arr
    qubo["couplings"] = quadratic_arr

    return nothing


end