@testset "newton.jl" begin
    booth(x) = (x[1] + 2*x[2] - 7)^2 + (2*x[1] + x[2] - 5)^2
    ∇booth(x) = [10*x[1] + 8*x[2] - 34, 8*x[1] + 10*x[2] - 38]
    Hbooth(x) = [10 8; 8 10]

    x = [4, 2]
    result = CubicEoS.newton(∇booth, Hbooth, x)
    @test result.converged
    @test result.argument ≈ [1, 3]
    @test booth(result.argument) ≈ 0 atol=1e-10
end