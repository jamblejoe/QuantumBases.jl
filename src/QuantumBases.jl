module QuantumBases

export AbstractBasis
export TensorBasis, AscendingTwoLevelBasis, NumberConservedBasis
export getstate, getstate!, getposition
export sites


abstract type AbstractBasis end

####################################################################
#
# Tensor Basis
#
####################################################################

struct TensorBasis <: AbstractBasis
    L::Int
end

Base.size(basis::TensorBasis) = (length(basis),)
Base.length(basis::TensorBasis) = 1 << basis.L
Base.isequal(b1::TensorBasis, b2::TensorBasis) = b1.L == b2.L

sites(basis::TensorBasis) = basis.L


####################################################################
#
# AscendingTwoLevelBasis
#
####################################################################
struct AscendingTwoLevelBasis <: AbstractBasis
    L::Int
end

# helper function
function digits_base2!(s::BitVector, index::Int64, L::Integer)
    L >= 1 || error("L must be greate than 1. Got L=$L.")
	s.len = L
    s.chunks .= reinterpret(UInt64, index)
    s.dims = (L,)
	s
end

function getposition(basis::AscendingTwoLevelBasis, state::AbstractVector)
    L = basis.L

	state in basis || error("state $state not in basis")
	index = 1
	for i in eachindex(state)
		#index += 2^(L-i) * state[i]
        index += state[i] << (L-i)
	end
	index
end

function getstate(basis::AscendingTwoLevelBasis, index::Integer)
    getstate!(BitVector(undef, basis.L), basis, index)
end

function getstate!(state::AbstractVector, basis::AscendingTwoLevelBasis, index::Integer)
    L = basis.L

    1<= index <= length(basis) || error("Index $index out of bounds [1,$(length(basis))]")

    digits!(state, index-1, base=2)
    reverse!(state)
    state
end

function getstate!(state::BitVector, basis::AscendingTwoLevelBasis, index::Int64)
    L = basis.L

    1<= index <= length(basis) || error("Index $index out of bounds [1,$(length(basis))]")
    index <= typemax(Int64) || error("index $index is larger than typemax(Int64)")

    digits_base2!(state, index-1, L)
    reverse!(state)
    state
end

#sites(basis::TensorBasis) = basis.L

Base.size(basis::AscendingTwoLevelBasis) = (length(basis),)
Base.length(basis::AscendingTwoLevelBasis) = 1 << basis.L
Base.isequal(b1::AscendingTwoLevelBasis, b2::AscendingTwoLevelBasis) = b1.L == b2.L

# Iterator interface
function Base.iterate(basis::AscendingTwoLevelBasis, index::Integer=1)
    1 <= index <= length(basis) ? (getstate(basis, index), index+1) : nothing
end

Base.eltype(::AscendingTwoLevelBasis) = BitVector

sites(basis::AscendingTwoLevelBasis) = basis.L

# Array interface
"""
Returns the basis element at position index.
"""
Base.getindex(basis::AscendingTwoLevelBasis, index::Integer) = getstate(basis, index)
Base.firstindex(::AscendingTwoLevelBasis) = 1
Base.lastindex(basis::AscendingTwoLevelBasis) = length(basis)

Base.in(state::AbstractVector, basis::AscendingTwoLevelBasis) = length(state)==basis.L && all(0 .<= state .<= 1)
Base.in(state::BitVector, basis::AscendingTwoLevelBasis) = length(state)==basis.L
Base.eachindex(basis::AscendingTwoLevelBasis) = 1:length(basis)


####################################################################
#
# Number Conserved Basis
#
####################################################################

struct NumberConservedBasis <:AbstractBasis
    L::Int
    N::Int
    Ds::Matrix{Int}
end

function NumberConservedBasis(L::Integer, N::Integer)

    L > 0 || error("L must be positive")
    N >= 0 || error("N must be >= 0")
    N <= L || error("N must be smaller than L")

    Ds = Matrix{Int}(undef, L+1, N+1)
    for i in 0:L
        for j in 0:N
            Ds[i+1,j+1] = binomial(i,j)
        end
    end

    NumberConservedBasis(L, N, Ds)

end

TotalSpinConservedBasis(parameters::Dict) = NumberConservedBasis(parameters["L"], parameters["N"])

@inline _D(basis::NumberConservedBasis, L::Integer, N::Integer) = basis.Ds[L+1, N+1]
@inline _D_unsafe(basis::NumberConservedBasis, L::Integer, N::Integer) = @inbounds basis.Ds[L+1, N+1]

function Base.length(basis::NumberConservedBasis)
    L = basis.L
    N = basis.N
    basis.Ds[L+1,N+1]
end

sites(basis::NumberConservedBasis) = basis.L
#Base.isequal(b1::NumberConservedBasis, b2::NumberConservedBasis) = b1.L == b2.L && b1.N == b2.N

"""
Returns the position of a state in the basis.
"""
function getposition(basis::NumberConservedBasis, state::AbstractVector)
    L = basis.L
    N = basis.N

    length(state) == L || throw(DomainError(L, "length of state must be $L"))
    #all(0 .<= state .<= N) || throw(DomainError(N, "components of state must be between 0 and $N"))
    for s in state
        0 <= s <= 1 || throw(DomainError(N, "components of state must be between 0 and 1"))
    end
    sum(state) == N || throw(DomainError(N, "components of state must sum to $N"))

    index = 1
    l = N
    for (m_l,n_i) in enumerate(state)
        if n_i == 1
            index += _D(basis, L-m_l, l)
            #index += _D_unsafe(basis, k-m_l, l)
            l -= 1
        end
    end
    index
end

"""
Returns state of the basis with position index.
"""
function getstate(basis::NumberConservedBasis, index::Integer)
    state = BitVector(undef, basis.L)
    #state .= 0
    getstate!(state, basis, index)
end

function getstate!(state::AbstractVector{T}, basis::NumberConservedBasis, index::Integer) where T
    L = basis.L
    N = basis.N

    one(index) <= index <= length(basis) || error("index $index out of bounds [1,$(length(basis))]")

    state .= zero(T)
    
    for i in N:-1:1
        m_i = i-1
        while _D(basis, m_i+1, i) < index
            m_i += one(index)
        end
        state[L-m_i] = one(T)
        index -= _D(basis, m_i, i)
    
    end
    
    state
end



Base.size(basis::NumberConservedBasis) = (length(basis),)
#Base.length(basis::NumberConservedBasis) = binomial(basis.L,basis.N)
Base.isequal(b1::NumberConservedBasis, b2::NumberConservedBasis) = b1.L == b2.L && b1.N == b2.N

# Iterator interface
function Base.iterate(basis::NumberConservedBasis, index::Integer=1)
    1 <= index <= length(basis) ? (getstate(basis, index), index+1) : nothing
end

Base.eltype(::NumberConservedBasis) = BitVector

# Array interface
"""
Returns the basis element at position index.
"""
Base.getindex(basis::NumberConservedBasis, index::Integer) = getstate(basis, index)
Base.firstindex(::NumberConservedBasis) = 1
Base.lastindex(basis::NumberConservedBasis) = length(basis)

function Base.in(state::AbstractVector, basis::NumberConservedBasis) 
    length(state)==basis.L && all(0 .<= state .<= 1) && sum(state)==basis.N
end
Base.in(state::BitVector, basis::NumberConservedBasis) = length(state)==basis.L && sum(state)==basis.N
Base.eachindex(basis::NumberConservedBasis) = 1:length(basis)





end
