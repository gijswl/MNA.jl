"""
    AbstractElement{T,N,M}

Abstract type for circuit elements. MNA stamps are defined per element type.
`T` encodes the value type, `N` is the number of nodes, and `M` the number of branch currents.
"""
abstract type AbstractElement{T, N, M} end

"""
    valuetype(element::AbstractElement)

Return the type of `element.value`.
"""
valuetype(::AbstractElement{T}) where {T} = T

"""
    num_voltages(element::AbstractElement)

Return the number of voltage unknowns (nodes) associated with the element.
"""
num_voltages(::AbstractElement{T, N, M}) where {T, N, M} = N

"""
    num_currents(element::AbstractElement)

Return the number of current unknowns associated with the element.
"""
num_currents(::AbstractElement{T, N, M}) where {T, N, M} = M

"""
    current_names(element::AbstractElement)

Return the names of the current unknowns associated with the element.
"""
current_names(::AbstractElement) = ()

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
abstract type AbstractSource{T, N, M} <: AbstractElement{T, N, M} end

"""
    AbstractControlledSource{T} <: AbstractSource{T}

Abstract type for sources controlled by circuit variables.
"""
abstract type AbstractControlledSource{T, N, M} <: AbstractSource{T, N, M} end

"""
    CurrentSource{T} <: AbstractSource{T}

Current source `Io` flowing into node 1 and out of node 2.
"""
struct CurrentSource{T} <: AbstractSource{T, 2, 0}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function CurrentSource(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("CurrentSource requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

function stamp(element::CurrentSource{T}, ::Any) where {T}
    Io = element.value
    A = @SMatrix zeros(T, 2, 2)
    b = SVector{2, T}(+Io, -Io)

    return A, b
end

"""
    VoltageSource <: AbstractSource

Voltage source `Uo` across node 1 to node 2.
Current unknown `I` flows into node 1 and out of node 2. 
"""
struct VoltageSource{T} <: AbstractSource{T, 2, 1}
    name::Symbol
    nodes::NTuple{2, Symbol}
    value::T

    function VoltageSource(name, nodes, value::T) where {T}
        length(nodes) == 2 || throw(ArgumentError("VoltageSource requires 2 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::VoltageSource) = (:I,)

function stamp(element::VoltageSource{T}, ::Any) where {T}
    Uo = element.value
    A = @SMatrix T[
        0  0 +1;
        0  0 -1;
        +1 -1  0
    ]
    b = SVector{3, T}(0, 0, Uo)

    return A, b
end

"""
    VCCS <: AbstractControlledSource

Voltage-controlled current source `Iout = G Uin`.
`Uin` is measured across node 1 to node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct VCCS{T} <: AbstractControlledSource{T, 4, 1}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function VCCS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("VCCS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::VCCS) = (:Iout,)

function stamp(element::VCCS{T}, ::Any) where {T}
    G = element.value
    A = @SMatrix T[
        0  0  0  0  0;
        0  0  0  0 +1;
        0  0  0  0 -1;
        0  0  0  0  0;
        +1  0  0 -1 -1 / G
    ]
    b = SVector{5, T}(0, 0, 0, 0, 0)

    return A, b
end

"""
    VCVS <: AbstractControlledSource

Voltage-controlled voltage source `Uout = G Uin`.
`Uin` is measured across node 1 to node 4, `Uout` is generated across node 2 to node 3.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct VCVS{T} <: AbstractControlledSource{T, 4, 1}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function VCVS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("VCVS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::VCVS) = (:Iout,)

function stamp(element::VCVS{T}, ::Any) where {T}
    G = element.value
    A = @SMatrix T[
        0  0  0  0  0;
        0  0  0  0 +1;
        0  0  0  0 -1;
        0  0  0  0  0;
        +G -1 +1 -G  0
    ]
    b = SVector{5, T}(0, 0, 0, 0, 0)

    return A, b
end

"""
    CCCS <: AbstractControlledSource

Current-controlled current source `Iout = G Iin`.
`Iin` is measured through into node 1 and out of node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct CCCS{T} <: AbstractControlledSource{T, 4, 1}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function CCCS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("CCCS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::CCCS) = (:Iout,)

function stamp(element::CCCS{T}, ::Any) where {T}
    G = element.value
    A = @SMatrix T[
        0  0  0  0 +1 / G;
        0  0  0  0 +1;
        0  0  0  0 -1;
        0  0  0  0 -1 / G;
        +1  0  0 -1  0
    ]
    b = SVector{5, T}(0, 0, 0, 0, 0)

    return A, b
end

"""
    CCVS <: AbstractControlledSource

Current-controlled voltage source `Uout = G Iin`.
Current unknown `Iin` is measured through into node 1 and out of node 4. `Uout` is generated across node 2 to node 3.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct CCVS{T} <: AbstractControlledSource{T, 4, 2}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function CCVS(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("CCVS requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::CCVS) = (:Iin, :Iout)

function stamp(element::CCVS{T}, ::Any) where {T}
    G = element.value
    A = @SMatrix T[
        0  0  0  0 +1  0;
        0  0  0  0  0 +1;
        0  0  0  0  0 -1;
        0  0  0  0 -1  0;
        0 +1 -1  0 -G  0;
        +1  0  0 -1  0  0
    ]
    b = SVector{6, T}(0, 0, 0, 0, 0, 0)

    return A, b
end


## Two-port elements
"""
    AbstractAdmittance{T}

The AbstractAdmittance represents one type of MNA stamp with several convenient subtypes (e.g., resistances, inductances, and capacitances).
"""
abstract type AbstractAdmittance{T} <: AbstractElement{T, 2, 0} end

function stamp(element::AbstractAdmittance, s)
    Y = admittance(element, s)
    T = typeof(Y)
    A = @SMatrix T[
        +Y -Y;
        -Y +Y
    ]
    b = SVector{2, T}(0, 0)

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
    Conductance <: AbstractAdmittance

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
    Inductance <: AbstractAdmittance

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
    Capacitance <: AbstractAdmittance

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
    Impedance <: AbstractAdmittance

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
    Admittance <: AbstractAdmittance

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
    Transformer <: AbstractElement

Ideal transformer with turns ratio `n:1`. 
Winding 1 at nodes 1-4, winding 2 at nodes 2-3.
Current unknown `It` flows into node 1 and out of node 4. The secondary current `n It` flows out of node 2 and into node 3.
"""
struct Transformer{T} <: AbstractElement{T, 4, 1}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function Transformer(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("Transformer requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::Transformer) = (:It,)

function stamp(element::Transformer{T}, ::Any) where {T}
    n = element.value
    A = @SMatrix T[
        0  0  0  0 +1;
        0  0  0  0 -n;
        0  0  0  0 +n;
        0  0  0  0 -1;
        +1 -n +n -1  0
    ]
    b = SVector{5, T}(0, 0, 0, 0, 0)

    return A, b
end

"""
    Gyrator <: AbstractElement

Ideal gyrator with ratio `R`.
```
Iin = 1/R * (V2 - V3)
Iout = -1/R * (V1 - V4)
```
Current unknown `Iin` flows into node 1 and out of node 4.
Current unknown `Iout` flows into node 2 and out of node 3.
"""
struct Gyrator{T} <: AbstractElement{T, 4, 2}
    name::Symbol
    nodes::NTuple{4, Symbol}
    value::T

    function Gyrator(name, nodes, value::T) where {T}
        length(nodes) == 4 || throw(ArgumentError("Gyrator requires 4 nodes"))
        return new{T}(Symbol(name), Tuple(Symbol.(nodes)), value)
    end
end

current_names(::Gyrator) = (:Iin, :Iout)

function stamp(element::Gyrator{T}, ::Any) where {T}
    R = element.value
    A = @SMatrix T[
        0  0  0  0 +1  0;
        0  0  0  0  0 +1;
        0  0  0  0  0 -1;
        0  0  0  0 -1  0;
        0 +1 -1  0 -R  0;
        +1  0  0 -1  0  R;
    ]
    b = SVector{6, T}(0, 0, 0, 0, 0, 0)

    return A, b
end
