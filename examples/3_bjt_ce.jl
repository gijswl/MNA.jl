#=
Example 3. Common-emitter amplifier using BJT
=#

using Symbolics
using MNA

@variables RE RC
@variables β rπ

## Voltage gain
@variables Vin

elements = [
    VoltageSource(:Vin, ("b", 0), Vin),
    Resistance(:rπ, ("b", 1), rπ),
    CCCS(:CCCS1, (1, "c", "e", "e"), β),
    Resistance(:RE, ("e", 0), RE),
    Resistance(:RC, ("c", 0), RC),
]

circuit = Circuit(elements)
A, b = assemble(circuit, 0.0)

gv = transfer_function(A, b, circuit, "b", "c")
gv = simplify(gv; expand = true)

## Input impedance
rin = -transfer_function(A, b, circuit, "Vin_I", "b")
rin = simplify(rin; expand = true)

## Current gain
@variables Iin

elements = [
    CurrentSource(:Iin, ("b", 0), Iin),
    Resistance(:rπ, ("b", 1), rπ),
    CCCS(:CCCS1, (1, "c", "e", "e"), β),
    Resistance(:RE, ("e", 0), RE),
    Resistance(:RC, ("c", 0), RC),
    ShortCircuit(:Iout, ("c", 0)),
]

circuit = Circuit(elements)
A, b = assemble(circuit, 0.0)

gi = MNA.cramer_solve(A, b, circuit, "Iout_I") / -Iin
gi = simplify(gi; expand = true)

## Sanity check
gv_analytic = expand(-β * RC / (rπ + (β + 1) * RE))
@assert isequal(gv_analytic, gv)

gi_analytic = β
@assert isequal(gi_analytic, gi)

rin_analytic = expand(rπ + (β + 1) * RE)
@assert isequal(rin_analytic, rin)
