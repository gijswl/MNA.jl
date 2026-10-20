## Circuit definition
V1 = 1
R1 = 1e3
R2 = 2e3

elements = [
    VoltageSource(:V1, ("Vin", 0), V1),
    Resistance(:R1, ("Vin", "Vout"), R1),
    Resistance(:R2, ("Vout", 0), R2),
]

circuit = Circuit(elements)

## Ground truth
expected_size = 3 # 2 nodes + 1 branch current
expected_unknowns = [
    "Vin", "Vout", # 2 nodes
    "V1_i1" # 1 branch current
]