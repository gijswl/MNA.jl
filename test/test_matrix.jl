circuits = ["circuit1", "circuit2", "circuit3"]

@testset "matrix" begin
    @testset "$name" for name in circuits
        include("circuits/$name.jl")

        A, b = assemble(circuit, frequency)

        # Check matrix size
        @test size(A) == (expected_size, expected_size)
        @test size(b) == (expected_size,)

        # Check solution
        u1 = MNA.matrix_solve(A, b, circuit, output_var)
        u2 = MNA.cramer_solve(A, b, circuit, output_var)

        if (typeof(u1) <: Num || typeof(u2) <: Num)
            u1 = simplify(u1 - expected_output; expand = true)
            u2 = simplify(u2 - expected_output; expand = true)

            @test isequal(u1, 0)
            @test isequal(u2, 0)
        else
            @test isapprox(u1, expected_output)
            @test isapprox(u2, expected_output)
        end
    end
end
