using QuantumBases
using Test


@testset "TensorBasis" begin

    @testset "L=2" begin
        
        basis = TensorBasis(2)
        @test getstate(basis, 1) == [0,0]
        @test getstate(basis, 2) == [0,1]
        @test getstate(basis, 3) == [1,0]
        @test getstate(basis, 4) == [1,1]
    end

    @testset "L=3" begin
        
        basis = TensorBasis(3)
        @test getstate(basis, 1) == [0,0,0]
        @test getstate(basis, 2) == [0,0,1]
        @test getstate(basis, 3) == [0,1,0]
        @test getstate(basis, 4) == [0,1,1]
        @test getstate(basis, 5) == [1,0,0]
        @test getstate(basis, 6) == [1,0,1]
        @test getstate(basis, 7) == [1,1,0]
        @test getstate(basis, 8) == [1,1,1]
    end


    @testset "getposition(getstate(..))" begin
        for L in 1:6
            basis = TensorBasis(L)
            for i in eachindex(basis)
                @test getstate(basis, i) in basis
                @test getposition(basis, getstate(basis, i)) == i
            end
        end
    end


    @testset "getstate!" begin
        L = 5
        basis = TensorBasis(L)
        for T in [Int] # floats do not work due to digits!
            state = zeros(T, L)
            @test getstate!(state, basis, 3) == getstate(basis, 3)
        end
    end

end

@testset "NumberConservedBasis" begin

    @testset "L=2, N=0" begin
        basis = NumberConservedBasis(2, 0)
        @test getstate(basis, 1) == [0,0]
    end

    @testset "L=2, N=1" begin
        basis = NumberConservedBasis(2, 1)
        @test getstate(basis, 1) == [0,1]
        @test getstate(basis, 2) == [1,0]
    end

    @testset "L=2, N=2" begin
        basis = NumberConservedBasis(2, 2)
        @test getstate(basis, 1) == [1,1]
    end

    @testset "L=3, N=0" begin
        basis = NumberConservedBasis(3, 0)
        @test getstate(basis, 1) == [0,0,0]
    end

    @testset "L=3, N=1" begin
        basis = NumberConservedBasis(3, 1)
        @test getstate(basis, 1) == [0,0,1]
        @test getstate(basis, 2) == [0,1,0]
        @test getstate(basis, 3) == [1,0,0]
    end

    @testset "L=3, N=2" begin
        basis = NumberConservedBasis(3, 2)
        @test getstate(basis, 1) == [0,1,1]
        @test getstate(basis, 2) == [1,0,1]
        @test getstate(basis, 3) == [1,1,0]
    end

    @testset "L=3, N=3" begin
        basis = NumberConservedBasis(3, 3)
        @test getstate(basis, 1) == [1,1,1]
    end

    @testset "getposition(getstate(..))" begin
        for L in 1:6
            for N in 1:L
                basis = NumberConservedBasis(L,N)
                for i in eachindex(basis)
                    @test getstate(basis, i) in basis
                    @test getposition(basis, getstate(basis, i)) == i
                end
            end
        end
    end

    @testset "getstate!" begin
        L = 5
        N = 2
        basis = NumberConservedBasis(L,N)
        for T in [Int, Float64, Float32]
            state = zeros(T, L)
            @test getstate!(state, basis, 3) == getstate(basis, 3)
        end
    end

end


