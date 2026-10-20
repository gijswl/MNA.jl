## Circuit definition
Vin = 1
rπ = 1e3
RE = 2.2e3
RC = 10e3
β = 150

elements = [
    VoltageSource(:Vin, ("b", 0), Vin),
    Resistance(:rπ, ("b", 1), rπ),
    CCCS(:CCCS1, (1, "c", "e", "e"), β),
    Resistance(:RE, ("e", 0), RE),
    Resistance(:RC, ("c", 0), RC),
]

circuit = Circuit(elements)

## Ground truth
expected_size = 6 # 4 nodes + 2 branch currents
expected_unknowns = [
    1, "b", "c", "e", # 4 nodes
    "CCCS1_i1", "Vin_i1" # 2 branch currents
]