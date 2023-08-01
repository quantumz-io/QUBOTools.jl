function _parse_linear(arr::Any)
    if (size(arr) == 0)
        return
    end
    data = Dict{Int,Float64}()
    for i in 1:size(arr, 1)
        data[i] = arr[i]
    end
    return data
end

function _parse_dense(matrix::Any)
    if (size(matrix) == 0)
        return 
    end
    data = Dict{Tuple{Int,Int},Float64}()
    num_rows, num_cols = size(matrix)

    for i in 1:num_rows
        for j in 1:num_cols 
            data[i, j] = matrix[i, j]
        end
    end

    return data
end

function _parse_sparse(i::Vector{Float64}, j::Vector{Float64}, v::Vector{Float64})
    data = Dict{Tuple{Int,Int},Float64}()
    for (idx, val) in enumerate(i)
        data[val, j[idx]] = v[idx]
    end
    return data

end


function _parse_data(file::HDF5.File, data::Dict{Symbol, Any})
    qubo = read(file, "Qubo")
    spectrum = read(file, "Spectrum")

    biases = qubo["biases"]
    if ("J_coo" in keys(qubo))
       j_coo = qubo["J_coo"]
       i = j_coo["I"]
       j = j_coo["J"]
       v = j_coo["V"]
       data[:quadratic_terms] = _parse_sparse(i, j, v)
    else
        couplings = qubo["couplings"]
        data[:quadratic_terms] = _parse_dense(couplings)
    end
    energies = spectrum["energies"]
    states = spectrum["states"]


    data[:linear_terms] = _parse_linear(biases)
    

end

function read_model(io::HDF5.File, fmt::HDF)

    data = Dict{Symbol, Any}(
        :linear_terms    => Dict{Int,Float64}(),
        :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
        :scale           => nothing,
        :offset          => nothing,
        :id              => nothing,
        :description     => nothing,
        :domain_size     => nothing,
        :linear_size     => nothing,
        :quadratic_size  => nothing,
    )

    _parse_data(io, data)
    
    return Model{Int, Float64, Int}(
        data[:linear_terms],
        data[:quadratic_terms];
        scale       = data[:scale],
        offset      = data[:offset],
        id          = data[:id],
        description = data[:description],
    )

    
end

