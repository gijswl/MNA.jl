using Symbolics
using MNA

@variables Vi R C s

elements = [
    VoltageSource(:V1, ("Vin", 0), Vi),
    Resistance(:R1, ("Vin", "Vout"), R),
    Capacitance(:C1, ("Vout", 0), C)
]

circuit = Circuit(elements)
A, b = assemble(circuit, s)

H = transfer_function(A, b, circuit, "Vin", "Vout")
H = simplify(H; expand = true)