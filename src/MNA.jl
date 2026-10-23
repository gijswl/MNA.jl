module MNA

using LinearAlgebra
using Symbolics

export CurrentSource, VoltageSource, VCCS, VCVS, CCCS, CCVS
export Resistance, Conductance, Impedance, Admittance, Inductance, Capacitance
export OpenCircuit, ShortCircuit
export Transformer, Gyrator
include("elements.jl")

export Circuit
export get_unknown
include("circuit.jl")

export assemble
include("matrix.jl")

export transfer_function, coefficients
include("transfer.jl")

end # module MNA
