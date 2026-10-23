circuits = ["circuit1", "circuit2"]

@testset "matrix" begin
    @testset "$name" for name in circuits
        include("circuits/$name.jl")

        A, b = assemble(circuit, 0.0)

        @test size(A) == (expected_size, expected_size)
        @test size(b) == (expected_size,)

        u1 = MNA.matrix_solve(A, b, circuit, output_var)
        u2 = MNA.cramer_solve(A, b, circuit, output_var)

        @test u1 ≈ expected_output
        @test u2 ≈ expected_output
    end
end
