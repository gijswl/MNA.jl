"""
    AbstractElement

Abstract type for circuit elements. MNA stamps are defined per element type.
"""
abstract type AbstractElement end

"""
    num_currents(element::AbstractElement)

Return the number of current unknowns associated with the element.
"""
function num_currents end

"""
    stamp(element::AbstractElement, s)

Return the stamp matrices `A` and `b`, evaluated at complex frequency `s`.
The size of the `A` is `N × N` and `b` is `N × 1`, where `N = n + m`
with `n` the number of voltage unknowns (nodes) and `m` the number of current unknowns.
"""
function stamp end


## Sources
"""
    AbstractSource <: AbstractElement

Abstract type for sources (e.g., of voltage and current).
"""
abstract type AbstractSource <: AbstractElement end

"""
    AbstractControlledSource <: AbstractSource

Abstract type for sources controlled by circuit variables.
"""
abstract type AbstractControlledSource <: AbstractSource end

"""
    CurrentSource <: AbstractSource

Current source `Io` flowing into node 1 and out of node 2.
"""
struct CurrentSource <: AbstractSource
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

CurrentSource(name::Symbol, nodes, value) = CurrentSource(name, Symbol.(nodes), value)

num_currents(::CurrentSource) = 0

function stamp(element::CurrentSource, ::Any)
    Io = element.value
    A = zeros(2, 2)
    b =  [
        +Io;
        -Io
    ]

    return A, b
end

"""
    VoltageSource <: AbstractSource

Voltage source `Uo` across node 1 to node 2.
Current unknown `Iout` flows into node 1 and out of node 2. 
"""
struct VoltageSource <: AbstractSource
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

VoltageSource(name::Symbol, nodes, value) = VoltageSource(name, Symbol.(nodes), value)

num_currents(::VoltageSource) = 1 # i1 = Iin

function stamp(element::VoltageSource, ::Any)
    Uo = element.value
    A = [ 
        0  0 +1;
        0  0 -1;
       +1 -1  0 
    ]
    b = [
        0;
        0;
        Uo
    ]

    return A, b
end

"""
    VCCS <: AbstractControlledSource

Voltage-controlled current source `Iout = G Uin`.
`Uin` is measured across node 1 to node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct VCCS <: AbstractControlledSource
    name::Symbol
    nodes::NTuple{4, Symbol}
    value
end

VCCS(name::Symbol, nodes, value) = VCCS(name, Symbol.(nodes), value)

num_currents(::VCCS) = 1 # i1 = Iout

function stamp(element::VCCS, ::Any)
    G = element.value
    A = [
         0  0  0  0  0;
         0  0  0  0 +1;
         0  0  0  0 -1;
         0  0  0  0  0;
        +1  0  0 -1 -1/G
    ]
    b = zeros(5)

    return A, b
end

"""
    VCVS <: AbstractControlledSource

Voltage-controlled voltage source `Uout = G Uin`.
`Uin` is measured across node 1 to node 4, `Uout` is generated across node 2 to node 3.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct VCVS <: AbstractControlledSource
    name::Symbol
    nodes::NTuple{4, Symbol}
    value
end

VCVS(name::Symbol, nodes, value) = VCVS(name, Symbol.(nodes), value)

num_currents(::VCVS) = 1 # i1 = Iout

function stamp(element::VCVS, ::Any)
    G = element.value
    A = [
         0  0  0  0  0;
         0  0  0  0 +1;
         0  0  0  0 -1;
         0  0  0  0  0;
        +G -1 +1 -G  0
    ]
    b = zeros(5)

    return A, b
end

"""
    CCCS <: AbstractControlledSource

Current-controlled current source `Iout = G Iin`.
`Iin` is measured through into node 1 and out of node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct CCCS <: AbstractControlledSource
    name::Symbol
    nodes::NTuple{4, Symbol}
    value
end

CCCS(name::Symbol, nodes, value) = CCCS(name, Symbol.(nodes), value)

num_currents(::CCCS) = 1 # i1 = Iout

function stamp(element::CCCS, ::Any)
    G = element.value
    A = [
         0  0  0  0 +1/G;
         0  0  0  0 +1;
         0  0  0  0 -1;
         0  0  0  0 -1/G;
        +1  0  0 -1  0
    ]
    b = zeros(5)

    return A, b
end

"""
    CCVS <: AbstractControlledSource

Current-controlled voltage source `Uout = G Iin`.
Current unknown `Iin` is measured through into node 1 and out of node 4. `Uout` is generated across node 2 to node 3.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct CCVS <: AbstractControlledSource
    name::Symbol
    nodes::NTuple{4, Symbol}
    value
end

CCVS(name::Symbol, nodes, value) = CCVS(name, Symbol.(nodes), value)

num_currents(::CCVS) = 2 # i1 = Iin, i2 = Iout

function stamp(element::CCVS, ::Any)
    G = element.value
    A = [
         0  0  0  0 +1  0;
         0  0  0  0  0 +1;
         0  0  0  0  0 -1;
         0  0  0  0 -1  0;
         0 +1 -1  0 -G  0;
        +1  0  0 -1  0  0
    ]
    b = zeros(6)

    return A, b
end


## Two-port elements
"""
    AbstractAdmittance

The AbstractAdmittance represents one type of MNA stamp with several convenient subtypes (e.g., resistances, inductances, and capacitances).
"""
abstract type AbstractAdmittance <: AbstractElement end

num_currents(::AbstractAdmittance) = 0

function stamp(element::AbstractAdmittance, s)
    Y = admittance(element, s)
    A =  [
        +Y -Y; 
        -Y +Y
    ]
    b = zeros(2)

    return A, b
end

"""
    admittance(element::AbstractAdmittance, s)

Return the admittance of the element, evaluated at complex frequency `s`.
"""
function admittance end

"""
    Resistance <: AbstractAdmittance

Element with a real admittance `Y = 1 / R`.
"""
struct Resistance <: AbstractAdmittance
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

Resistance(name::Symbol, nodes, value) = Resistance(name, Symbol.(nodes), value)

admittance(element::Resistance, ::Any) = 1 / element.value

"""
    Conductance <: AbstractAdmittance

Element with a real admittance `Y = G`.
"""
struct Conductance <: AbstractAdmittance
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

Conductance(name::Symbol, nodes, value) = Conductance(name, Symbol.(nodes), value)

admittance(element::Conductance, ::Any) = element.value

"""
    Inductance <: AbstractAdmittance

Element with a complex admittance `Y = 1 / sL`.
"""
struct Inductance <: AbstractAdmittance
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

Inductance(name::Symbol, nodes, value) = Inductance(name, Symbol.(nodes), value)

admittance(element::Inductance, s::Any) = 1 / (s * element.value)

"""
    Capacitance <: AbstractAdmittance

Element with a complex admittance `Y = sC`.
"""
struct Capacitance <: AbstractAdmittance
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

Capacitance(name::Symbol, nodes, value) = Capacitance(name, Symbol.(nodes), value)

admittance(element::Capacitance, s::Any) = s * element.value

"""
    Impedance <: AbstractAdmittance

Element with a complex admittance `Y = 1 / Z`.
"""
struct Impedance <: AbstractAdmittance
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

Impedance(name::Symbol, nodes, value) = Impedance(name, Symbol.(nodes), value)

admittance(element::Impedance, ::Any) = 1 / element.value

"""
    Admittance <: AbstractAdmittance

Element with a complex admittance `Y`.
"""
struct Admittance <: AbstractAdmittance
    name::Symbol
    nodes::NTuple{2, Symbol}
    value
end

Admittance(name::Symbol, nodes, value) = Admittance(name, Symbol.(nodes), value)

admittance(element::Admittance, ::Any) = element.value


"""
    OpenCircuit 

"""
OpenCircuit(name::Symbol, nodes) = CurrentSource(name, nodes, 0)

"""
    ShortCircuit

"""
ShortCircuit(name::Symbol, nodes) = VoltageSource(name, nodes, 0)

## Four-port elements
"""
    Transformer <: AbstractElement

Ideal transformer with turns ratio `T:1`. 
Winding 1 at nodes 1-4, winding 2 at nodes 2-3.
Current unknown `It` flows into node 1 and out of node 4. The secondary current `T It` flows out of node 2 and into node 3.
"""
struct Transformer <: AbstractElement
    name::Symbol
    nodes::NTuple{4, Symbol}
    value
end
Transformer(name::Symbol, nodes, value) = Transformer(name, Symbol.(nodes), value)

num_currents(::Transformer) = 1 # i1 = It

function stamp(element::Transformer, ::Any)
    T = element.value
    A = [
         0  0  0  0 +1;
         0  0  0  0 -T;
         0  0  0  0 +T;
         0  0  0  0 -1;
        +1 -T +T -1  0
    ]
    b = zeros(5)

    return A, b
end