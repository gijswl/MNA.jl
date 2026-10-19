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
    (Transformer, 4)
]

nodes = [
    "a", "b", "c", 1, 2, 3, :d, :e
]

@testset "elements" begin
    @testset "$el_type" for (el_type, nnodes) in elements
        el_nodes = rand(nodes, nnodes)
        el_value = rand()
        el = el_type(:el, Tuple(el_nodes), el_value)

        for i in 1:nnodes 
            @test el.nodes[i] == Symbol(el_nodes[i])
        end

        stamp_size = nnodes + MNA.num_currents(el)
        A, b = MNA.stamp(el, 1e3 * rand())
        @test size(A) == (stamp_size, stamp_size)
        @test size(b) == (stamp_size,)
    end
end