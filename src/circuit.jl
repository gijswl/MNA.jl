"""
    IndexedElement{E, N}

Stores a circuit element of type `E` and its unknown indices of length `N`.
"""
struct IndexedElement{E, N}
    element::E
    index::SVector{N, Int}
end

"""
    Circuit

Struct representing a circuit consisting of a number of elements (<:AbstractElement).
Upon construction, the unknowns (nodal voltages and independent branch currents) are extracted from the netlist.
The node name `0` is reserved for global ground and must be present at least once in a circuit.
"""
struct Circuit{T}
    elements::Vector{IndexedElement}
    unknowns::Dict{Symbol, Int}
    nvoltages::Int
    ncurrents::Int

    function Circuit(elements::Vector{<:AbstractElement})
        # Determine the circuit unknowns
        voltages, nvoltages = process_voltages(elements)
        currents, ncurrents = process_currents(elements)

        unknowns = merge(
            Dict(Symbol(0) => 0),
            Dict([u for u in zip(voltages, 1:nvoltages)]),
            Dict([u for u in zip(currents, (nvoltages + 1):(nvoltages + ncurrents))])
        )

        # Determine the element indices from the unknowns
        indices = process_indices(elements, unknowns)

        # Determine the value type of the circuit for constructing the system matrix
        T = promote_type(map(valuetype, elements)...)

        return new{T}(indices, unknowns, nvoltages, ncurrents)
    end
end

"""
    size(circuit::Circuit)

Return the size of the system matrix `[A]{u} = {b}`.
This should be equal to the length of `unknowns(circuit) - 1`.
"""
size(circuit::Circuit) = circuit.nvoltages + circuit.ncurrents

"""
    elements(circuit::Circuit)

Return the elements of the circuit with the AbstractElement type and 
"""
elements(circuit::Circuit) = circuit.elements

"""
    unknowns(circuit::Circuit)

Return a dictionary of unknowns where `key` is the unknown name, and `value` is its index in the system matrix.
Only the unknown `Symbol(0)` is not present in the system matrix and always points to index `0`.
"""
unknowns(circuit::Circuit) = circuit.unknowns

"""
    get_unknown_idx(circuit::Circuit, name)
    get_unknown_idx(unknowns::Dict, name)

Return the index or indices belonging to the unknown(s) `name`.
"""
get_unknown_idx(circuit::Circuit, name) = get_unknown_idx(unknowns(circuit), name)

function get_unknown_idx(unknowns::Dict, name::Symbol)
    return unknowns[name]
end

function get_unknown_idx(unknowns::Dict, name)
    N = length(name)
    return SVector{N, Int}(getindex.(Ref(unknowns), name))
end

"""
    process_voltages(elements::Vector{<:AbstractElement})

Return a list of node names representing the nodal voltage unknowns and its length.
The list is sorted, contains only unique entries, and does not contain the symbol `Symbol(0)`.
"""
function process_voltages(elements::Vector{<:AbstractElement})
    nodes = Symbol[]
    for element in elements
        append!(nodes, element.nodes)
    end

    unique!(nodes)
    sort!(nodes)
    nnodes = length(nodes)

    setdiff!(nodes, [Symbol(0)])
    @assert length(nodes) == nnodes - 1 "No reference node '0' in circuit."

    return nodes, length(nodes)
end

"""
    process_currents(elements::Vector{<:AbstractElement})

Return a list of unknowns representing the independent branch currents and its length.
The list is sorted and formatted as `[element.name]_i[idx]`, where `idx = 1,...,n` and `n` is the number of unknowns for that element.
"""
function process_currents(elements::Vector{<:AbstractElement})
    currents = Symbol[]
    for element in elements
        for current_name in current_names(element)
            push!(currents, Symbol(element.name, "_", current_name))
        end
    end

    sort!(currents)

    return currents, length(currents)
end

"""
    process_indices(elements::Vector{<:AbstractElement}, unknowns::Dict)

Translate unknown names to indices of the system matrix, returning a vector of `IndexedElement`.
"""
function process_indices(elements::Vector{<:AbstractElement}, unknowns::Dict)
    indices = IndexedElement[]

    for element in elements
        unames = (
            element.nodes...,
            (Symbol(element.name, "_", c) for c in current_names(element))...,
        )
        idx = get_unknown_idx(unknowns, unames)

        push!(indices, IndexedElement(element, idx))
    end

    return indices
end
