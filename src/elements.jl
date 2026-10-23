"""
    AbstractElement{T}

Abstract type for circuit elements. MNA stamps are defined per element type.
"""
abstract type AbstractElement{T} end

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

"""
    valuetype(element::AbstractElement)

Return the type of `element.value`.
"""
valuetype(::AbstractElement{T}) where {T} = T

## Sources
"""
    AbstractSource{T} <: AbstractElement{T}

Abstract type for sources (e.g., of voltage and current).
"""
abstract type AbstractSource{T} <: AbstractElement{T} end

"""
    AbstractControlledSource{T} <: AbstractSource{T}

Abstract type for sources controlled by circuit variables.
"""
abstract type AbstractControlledSource{T} <: AbstractSource{T} end

"""
    CurrentSource{T} <: AbstractSource{T}

Current source `Io` flowing into node 1 and out of node 2.
"""
struct CurrentSource{T} <: AbstractSource{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function CurrentSource(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("CurrentSource requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

num_currents(::CurrentSource) = 0

function stamp(element::CurrentSource, ::Any)
    Io = element.value
    A = zeros(2, 2)
    b = [
        +Io;
        -Io
    ]

    return A, b
end

"""
    VoltageSource{T} <: AbstractSource{T}

Voltage source `Uo` across node 1 to node 2.
Current unknown `Iout` flows into node 1 and out of node 2. 
"""
struct VoltageSource{T} <: AbstractSource{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function VoltageSource(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("VoltageSource requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

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
    VCCS{T} <: AbstractControlledSource{T}

Voltage-controlled current source `Iout = G Uin`.
`Uin` is measured across node 1 to node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct VCCS{T} <: AbstractControlledSource{T}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function VCCS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("VCCS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

num_currents(::VCCS) = 1 # i1 = Iout

function stamp(element::VCCS, ::Any)
    G = element.value
    A = [
        0  0  0  0  0;
        0  0  0  0 +1;
        0  0  0  0 -1;
        0  0  0  0  0;
        +1  0  0 -1 -1 / G
    ]
    b = zeros(5)

    return A, b
end

"""
    VCVS{T} <: AbstractControlledSource{T}

Voltage-controlled voltage source `Uout = G Uin`.
`Uin` is measured across node 1 to node 4, `Uout` is generated across node 2 to node 3.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct VCVS{T} <: AbstractControlledSource{T}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function VCVS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("VCVS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

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
    CCCS{T} <: AbstractControlledSource{T}

Current-controlled current source `Iout = G Iin`.
`Iin` is measured through into node 1 and out of node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct CCCS{T} <: AbstractControlledSource{T}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function CCCS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("CCCS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

num_currents(::CCCS) = 1 # i1 = Iout

function stamp(element::CCCS, ::Any)
    G = element.value
    A = [
        0  0  0  0 +1 / G;
        0  0  0  0 +1;
        0  0  0  0 -1;
        0  0  0  0 -1 / G;
        +1  0  0 -1  0
    ]
    b = zeros(5)

    return A, b
end

"""
    CCVS{T} <: AbstractControlledSource{T}

Current-controlled voltage source `Uout = G Iin`.
Current unknown `Iin` is measured through into node 1 and out of node 4. `Uout` is generated across node 2 to node 3.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct CCVS{T} <: AbstractControlledSource{T}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function CCVS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("CCVS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

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
    AbstractAdmittance{T}

The AbstractAdmittance represents one type of MNA stamp with several convenient subtypes (e.g., resistances, inductances, and capacitances).
"""
abstract type AbstractAdmittance{T} <: AbstractElement{T} end

num_currents(::AbstractAdmittance) = 0

function stamp(element::AbstractAdmittance, s)
    Y = admittance(element, s)
    A = [
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
    Resistance{T} <: AbstractAdmittance{T}

Element with a real admittance `Y = 1 / R`.
"""
struct Resistance{T} <: AbstractAdmittance{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function Resistance(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("Resistance requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

admittance(element::Resistance, ::Any) = 1 / element.value

"""
    Conductance{T} <: AbstractAdmittance{T}

Element with a real admittance `Y = G`.
"""
struct Conductance{T} <: AbstractAdmittance{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function Conductance(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("Conductance requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

admittance(element::Conductance, ::Any) = element.value

"""
    Inductance{T} <: AbstractAdmittance{T}

Element with a complex admittance `Y = 1 / sL`.
"""
struct Inductance{T} <: AbstractAdmittance{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function Inductance(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("Inductance requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

admittance(element::Inductance, s::Any) = 1 / (s * element.value)

"""
    Capacitance{T} <: AbstractAdmittance{T}

Element with a complex admittance `Y = sC`.
"""
struct Capacitance{T} <: AbstractAdmittance{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function Capacitance(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("Capacitance requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

admittance(element::Capacitance, s::Any) = s * element.value

"""
    Impedance{T} <: AbstractAdmittance{T}

Element with a complex admittance `Y = 1 / Z`.
"""
struct Impedance{T} <: AbstractAdmittance{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function Impedance(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("Impedance requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

admittance(element::Impedance, ::Any) = 1 / element.value

"""
    Admittance{T} <: AbstractAdmittance{T}

Element with a complex admittance `Y`.
"""
struct Admittance{T} <: AbstractAdmittance{T}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function Admittance(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("Admittance requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

admittance(element::Admittance, ::Any) = element.value


"""
    OpenCircuit 

"""
OpenCircuit(name, nodes) = CurrentSource(name, nodes, 0)

"""
    ShortCircuit

"""
ShortCircuit(name, nodes) = VoltageSource(name, nodes, 0)

## Four-port elements
"""
    Transformer{T} <: AbstractElement{T}

Ideal transformer with turns ratio `T:1`. 
Winding 1 at nodes 1-4, winding 2 at nodes 2-3.
Current unknown `It` flows into node 1 and out of node 4. The secondary current `T It` flows out of node 2 and into node 3.
"""
struct Transformer{T} <: AbstractElement{T}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function Transformer(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("Transformer requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

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

"""
    Gyrator{T} <: AbstractElement{T}

Ideal gyrator with ratio `R`.
```
Iin = 1/R * (V2 - V3)
Iout = -1/R * (V1 - V4)
```
Current unknown `Iin` flows into node 1 and out of node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct Gyrator{T} <: AbstractElement{T}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function Gyrator(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("Gyrator requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

num_currents(::Gyrator) = 2 # i1 = Iin, i2 = Iout

function stamp(element::Gyrator, ::Any)
    R = element.value
    A = [
        0  0  0  0 +1  0;
        0  0  0  0  0 +1;
        0  0  0  0  0 -1;
        0  0  0  0 -1  0;
        0 +1 -1  0 -R  0;
        +1  0  0 -1  0  R;
    ]
    b = zeros(6)

    return A, b
end
