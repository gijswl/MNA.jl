circuits = ["circuit1", "circuit2"]

@testset "circuit" begin
    @testset "$name" for name in circuits
        include("circuits/$name.jl")

        unames = MNA.unknowns(circuit)

        @test MNA.size(circuit) == expected_size
        @test length(unames) == expected_size + 1

        @test MNA.get_unknown_idx(circuit, Symbol(0)) == 0
        for (idx, unknown) in enumerate(expected_unknowns)
            @test MNA.get_unknown_idx(circuit, Symbol(unknown)) == idx
        end
    end
end
