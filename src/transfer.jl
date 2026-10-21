using Symbolics: coeff, degree, numerator, denominator

"""
    transfer_function(A::Matrix, b::Vector, circuit::Circuit, in, out)

Return the transfer function between circuit unknowns `in` and `out`.
"""
function transfer_function(A::Matrix, b::Vector, circuit::Circuit, in, out)
    uin = cramer_solve(A, b, circuit, in)
    uout = cramer_solve(A, b, circuit, out)
    return uout / uin
end

"""
    coefficients(tf::Num, var::Num)

Return the numerator and denominator coefficients of `tf` for variable `var`. `var` would typically be `f`, `ω`, or `s`.
The coefficients are returned in an array with increasing order of `var`, i.e., 
```
tf(s) = (s + 2) / (s^2 + 2s + 3)
```
would return `num = [2, 1]` and `den = [3, 2, 1]`
"""
function coefficients(tf::Num, var::Num)
    expr = (numerator(tf), denominator(tf))
    ord = degree.(expr, var)

    num = coeff.(Ref(expr[1]), var .^ (0:ord[1]))
    den = coeff.(Ref(expr[2]), var .^ (0:ord[2]))

    return num, den
end
