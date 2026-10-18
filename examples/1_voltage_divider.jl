using Symbolics
using MNA

@variables Vi R1 R2 s
    
elements = [
    VoltageSource(:V1, ("Vin", 0), Vi),
    Resistance(:R1, ("Vin", "Vout"), R1),
    Resistance(:R2, ("Vout", 0), R2)
]

circuit = Circuit(elements)
A, b = assemble(circuit, s)

H = transfer_function(A, b, circuit, "Vin", "Vout")
H = simplify(H, expand = true)