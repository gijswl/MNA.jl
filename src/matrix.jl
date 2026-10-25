"""
    assemble(circuit::Circuit, s)

Assemble the system matrix `[A]{u} = {b}` at complex frequency `s`.
"""
function assemble(circuit::Circuit{T}, s::S) where {T, S}
    # Determine system matrix size and type
    N = size(circuit)
    M = promote_type(T, S)

    # Initialize system matrix
    A = zeros(M, N, N)
    b = zeros(M, N)

    # Element assembly
    for ie in elements(circuit)
        assemble_element!(A, b, ie, s)
    end

    return A, b
end

"""
    assemble_element!(A, b, ie::IndexedElement, s)

Type-stable element assembly sub-routine.
"""
@inline function assemble_element!(A, b, ie::IndexedElement{E, N}, s) where {E, N}
    A_, b_ = stamp(ie.element, s)
    idx = ie.index

    # Add element-wise to avoid issues with duplicate indices.
    #  e.g., the contribution of a resistance connected with both pins to the same node should cancel.
    for (i, x) in enumerate(idx)
        x == 0 && continue # Discard the row if it is assigned to node 0 (global ground)

        b[x] += b_[i]
        for (j, y) in enumerate(idx)
            y == 0 && continue # Discard the column if it is assigned to node 0 (global ground)

            A[x, y] += A_[i, j]
        end
    end
    return
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
