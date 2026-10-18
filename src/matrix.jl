"""
    assemble(circuit::Circuit, s::Any)

Assemble the system matrix `[A]{u} = {b}` at complex frequency `s`.
"""
function assemble(circuit::Circuit, s::Any)
    N = size(circuit)

    A = zeros(typeof(s), N, N)
    b = zeros(typeof(s), N)

    for element ∈ circuit.elements
        A_, b_ = stamp(element, s)

        # Translate unknown names to indices of the system matrix
        unames = collect(element.nodes)
        for i ∈ 1:num_currents(element)
            push!(unames, Symbol(element.name, "_i", i))
        end
        idx = get_unknown_idx(circuit, unames)

        # Handle the ground node by discarding all matrix entries assigned to position 0.
        nonzeros = ispositive.(idx)
        idx = idx[nonzeros]
        A_ = A_[nonzeros, nonzeros]
        b_ = b_[nonzeros]
        
        # Add element-wise to avoid issues with duplicate indices.
        #  e.g., the contribution of a resistance connected with both pins to the same node should cancel.
        for (i, x) ∈ enumerate(idx)
            for (j, y) ∈ enumerate(idx)
                A[x, y] += A_[i, j]
            end
            b[x] += b_[i]
        end
    end

    return A, b
end

"""
    matrix_solve(A::Matrix, b::Vector, circuit::Circuit, var)

Solve the system equation `[A]{u} = {b}` for circuit unknown `var` using backslash solve.
This is more efficient for non-symbolic problems and can be applied to multiple unknowns at the same time.
"""
function matrix_solve(A::Matrix, b::Vector, circuit::Circuit, var)
    u = A \ b
    return get_unknown(u, circuit, var)
end

"""
    cramer_solve(A::Matrix, b::Vector, circuit::Circuit, var)

Solve the system equation `A u = b` for circuit unknown `var` using Cramer's rule.
This is more efficient for large symbolic problems than using the backslash solve.
"""
function cramer_solve(A::Matrix, b::Vector, circuit::Circuit, var)
    var_idx = get_unknown_idx(circuit, Symbol(var))

    Ac = copy(A)
    Ac[:, var_idx] = b
    return det(Ac) / det(A)
end

"""
    get_unknown(u, circuit::Circuit, name)

Return the entry or entries in `u` corresponding to the unknown(s) `name`.
"""
get_unknown(u, circuit::Circuit, name) = u[get_unknown_idx(circuit, Symbol.(name))]