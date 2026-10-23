elements = [
    (CurrentSource, 2),
    (VoltageSource, 2),
    (VCCS, 4),
    (VCVS, 4),
    (CCCS, 4),
    (CCVS, 4),
    (Resistance, 2),
    (Conductance, 2),
    (Impedance, 2),
    (Admittance, 2),
    (Inductance, 2),
    (Capacitance, 2),
    (Transformer, 4),
    (Gyrator, 4),
]

nodes = [
    "a", "b", "c", 1, 2, 3, :d, :e,
]

@testset "elements" begin
    @testset "$el_type" for (el_type, nnodes) in elements
        el_nodes = rand(nodes, nnodes)
        el_value = rand()
        el = el_type("$el_value", el_nodes, el_value)

        # Check node names
        for i in 1:nnodes
            @test el.nodes[i] == Symbol(el_nodes[i])
        end

        # Check stamp size against number of unknowns
        stamp_size = nnodes + MNA.num_currents(el)
        A, b = MNA.stamp(el, 1.0e3 * rand())
        @test size(A) == (stamp_size, stamp_size)
        @test size(b) == (stamp_size,)

        # Deliberately construct element with wrong number of nodes
        @test_throws ArgumentError el_type("$el_value", rand(nodes, nnodes + 1), el_value)
    end
end
