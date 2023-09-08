using QuantumBases
using Test


@testset "TensorBasis" begin

@testset "Base" begin 
    
    basis = TensorBasis(2)
    @test length(basis) == 4

    basis2 = TensorBasis(2)
    @test isequal(basis, basis2)

    basis3 = TensorBasis(3)
    @test !isequal(basis, basis3)
end


end


