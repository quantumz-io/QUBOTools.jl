function _write_linear(data::Dict{Int64, Float64}, model::AbstractModel)
    arr = zeros(domain_size(model))
    for i in data
        arr[i[1]] = i[2]
    end
    return arr
end

function _write_quadratic(data::Dict{Tuple{Int64, Int64}, Float64}, model::AbstractModel)
    arr = zeros(domain_size(model), domain_size(model))
    for i in data
        arr[i[1][1], i[1][2]] = i[2]
    end
    return arr
end

function _write_quadratic_sparse(data::Dict{Tuple{Int64, Int64}, Float64}, model::AbstractModel)
    i = zeros(domain_size(model))
    j = zeros(domain_size(model))   
    v = zeros(domain_size(model))   
    for (idx, val) in enumerate(data)
        i[idx] = val[1][1]
        j[idx] = val[1][2]
        v[idx] = val[2]
    end
    return i, j, v
end

function write_model(io::HDF5.File, model::AbstractModel, fmt::HDF)
    qubo = create_group(io, "Qubo")
    spectrum = create_group(io, "Spectrum")
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

    linear_arr = _write_linear(data[:linear_terms], model)    

    if (linear_density(model) < 1.0)
        i, j, v = _write_quadratic_sparse(data[:quadratic_terms], model)
       jcoo = create_group(qubo, "J_coo")
       jcoo["I"] = i
       jcoo["J"] = j
       jcoo["V"] = v
    
    else
        quadratic_arr = _write_quadratic(data[:quadratic_terms], model)
        qubo["couplings"] = quadratic_arr
    end

    
    qubo["biases"] = linear_arr
    spectrum["energies"] = [0;0]
    spectrum["states"] = [0;0]

    return nothing


end