"""
    transfer_function(A::Matrix, b::Vector, circuit::Circuit, in, out)

Calculate the transfer function between circuit unknowns `in` and `out`.
"""
function transfer_function(A::Matrix, b::Vector, circuit::Circuit, in, out)
    uin = cramer_solve(A, b, circuit, in)
    uout = cramer_solve(A, b, circuit, out)
    return uout / uin
end