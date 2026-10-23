## Circuit definition
V1 = 1.0
@variables R C s

frequency = s

elements = [
    VoltageSource(:V1, ("Vin", 0), V1),
    Resistance(:R1, ("Vin", "Vout"), R),
    Capacitance(:C1, ("Vout", 0), C),
]

circuit = Circuit(elements)

## Ground truth
expected_size = 3 # 2 nodes + 1 branch current
expected_unknowns = [
    "Vin", "Vout", # 2 nodes
    "V1_I", # 1 branch current
]

output_var = "Vout"
expected_output = V1 / (1 + s * R * C)
