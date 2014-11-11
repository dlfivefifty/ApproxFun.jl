export Operator,Functional,InfiniteOperator
export bandrange, linsolve, periodic
export dirichlet, neumann
export ldirichlet,rdirichlet,lneumann,rneumann
export ldiffbc,rdiffbc,diffbcs




abstract Operator{T} #T is the entry type, Float64 or Complex{Float64}
abstract Functional{T} <: Operator{T}
abstract InfiniteOperator{T} <: Operator{T}   #Infinite Operators have + range
abstract BandedBelowOperator{T} <: InfiniteOperator{T}
abstract BandedOperator{T} <: BandedBelowOperator{T}

Base.eltype{T}(::Operator{T})=T




## We assume operators are T->T
rangespace(A::Operator)=AnySpace()
domainspace(A::Operator)=AnySpace()
rangespace(A::Functional)=ScalarSpace()
domain(A::Operator)=domain(domainspace(A))




Base.size(::InfiniteOperator)=[Inf,Inf]
Base.size(::Functional)=Any[1,Inf] #use Any vector so the 1 doesn't become a float
Base.size(op::Operator,k::Integer)=size(op)[k]


## geteindex

Base.getindex(op::Operator,k::Integer,j::Integer)=op[k:k,j:j][1,1]
Base.getindex(op::Operator,k::Integer,j::Range1)=op[k:k,j][1,:]
Base.getindex(op::Operator,k::Range1,j::Integer)=op[k,j:j][:,1]
Base.getindex(op::Functional,k::Integer)=op[k:k][1]

function Base.getindex(op::Functional,j::Range1,k::Range1)
  @assert j[1]==1 && j[end]==1
  op[k].'
end
function Base.getindex(op::Functional,j::Integer,k::Range1)
  @assert j==1
  op[k].'
end



function Base.getindex(B::Operator,k::Range1,j::Range1)
    BandedArray(B,k,j)[k,j]
end



## bandrange and indexrange

bandrange(b::BandedBelowOperator)=Range1(bandinds(b)...)
function bandrangelength(B::BandedBelowOperator)
    bndinds=bandinds(B)
    bndinds[end]-bndinds[1]+1
end


function columninds(b::BandedBelowOperator,k::Integer)
    ret = bandinds(b)
  
    (ret[1]  + k < 1) ? (1,(ret[end] + k)) : (ret[1]+k,ret[2]+k)
end

##TODO: Change to columnindexrange to match BandedOperator
indexrange(b::BandedBelowOperator,k::Integer)=Range1(columninds(b,k)...)




index(b::BandedBelowOperator)=1-bandinds(b)[1]  # index is the equivalent of BandedArray.index



## Construct operators


ShiftArray{T<:Number}(B::Operator{T},k::Range1,j::Range1)=addentries!(B,sazeros(T,k,j),k)
ShiftArray(B::Operator,k::Range1)=ShiftArray(B,k,bandrange(B))
BandedArray(B::Operator,k::Range1)=BandedArray(B,k,(k[1]+bandinds(B)[1]):(k[end]+bandinds(B)[end]))
BandedArray(B::Operator,k::Range1,cs)=BandedArray(ShiftArray(B,k,bandrange(B)),cs)


## Default addentries!
# this allows for just overriding getdiagonalentry


function addentries!(B::BandedOperator,A,kr)
        br=bandinds(B)
    for k=(max(kr[1],1)):(kr[end])
        for j=max(br[1],1-k):br[end]
            A[k,j]=getdiagonalentry(B,k,j)
        end
    end
    
    A
end

## Default Composition with a Fun, LowRankFun, and TensorFun

Base.getindex(B::BandedOperator,f::Fun) = B*Multiplication(f,domainspace(B))
Base.getindex(B::BandedOperator,f::LowRankFun) = PlusOperator(BandedOperator[f.A[i]*B[f.B[i]] for i=1:rank(f)])
Base.getindex(B::BandedOperator,f::TensorFun) = B[LowRankFun(f)]

## Standard Operators and linear algebra


include("ShiftOperator.jl")
include("linsolve.jl")

include("spacepromotion.jl")
include("ToeplitzOperator.jl")
include("ConstantOperator.jl")
include("TridiagonalOperator.jl")


## Operators overrided for spaces

include("Conversion.jl")
include("Multiplication.jl")
include("calculus.jl")
include("Evaluation.jl")



include("SavedOperator.jl")
include("AlmostBandedOperator.jl")
include("adaptiveqr.jl")


include("algebra.jl")

include("TransposeOperator.jl")
include("StrideOperator.jl")
include("SliceOperator.jl")
include("CompactOperator.jl")


include("null.jl")
include("systems.jl")



## Conversion


Base.zero{T<:Number}(::Type{Functional{T}})=ZeroFunctional(T)
Base.zero{T<:Number}(::Type{Operator{T}})=ZeroOperator(T)
Base.zero{O<:Functional}(::Type{O})=ZeroFunctional()
Base.zero{O<:Operator}(::Type{O})=ZeroOperator()


# TODO: can convert return different type?
Base.convert{T<:Operator}(A::Type{T},n::Number)=n==0?ZeroOperator():ConstantOperator(n)
Base.convert{T<:Operator}(A::Type{T},n::UniformScaling)=n.λ==0?ZeroOperator():ConstantOperator(n)


## Promotion

for T in (:Float64,:Int64,:(Complex{Float64}))
    @eval Base.promote_rule{N<:Number,O<:Operator{$T}}(::Type{N},::Type{O})=Operator{promote_type(N,$T)}
    @eval Base.promote_rule{N<:Number,O<:Operator{$T}}(::Type{UniformScaling{N}},::Type{O})=Operator{promote_type(N,$T)}    
end

Base.promote_rule{N<:Number,O<:Operator}(::Type{N},::Type{O})=Operator
Base.promote_rule{N<:UniformScaling,O<:Operator}(::Type{N},::Type{O})=Operator



