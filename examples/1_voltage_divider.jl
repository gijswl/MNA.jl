#=
Example 1. Resistive voltage divider
=#

using Symbolics
using MNA

@variables R1 R2
@variables Vi

elements = [
    VoltageSource(:V1, ("Vin", 0), Vi),
    Resistance(:R1, ("Vin", "Vout"), R1),
    Resistance(:R2, ("Vout", 0), R2),
]

circuit = Circuit(elements)
A, b = assemble(circuit, 0.0)

H = transfer_function(A, b, circuit, "Vin", "Vout")
H = simplify(H, expand = true)

##
component_values = Dict(
    R1 => 10.0e3,
    R2 => 20.0e3
)
Hnum = substitute(H, component_values)
