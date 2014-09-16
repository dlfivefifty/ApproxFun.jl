immutable Multiplication{T<:Number,D<:FunctionSpace,S<:FunctionSpace} <: BandedOperator{T}
    f::Fun{T,D}
    space::S
end

Multiplication(f::Fun)=Multiplication(f,space(f))

Multiplication(c::Number)=ConstantOperator(c)




domainspace(M::Multiplication)=M.space
rangespace(M::Multiplication)=M.space





bandinds(T::Multiplication)=(1-length(T.f.coefficients),length(T.f.coefficients)-1)
domain(T::Multiplication)=domain(T.f)



##multiplication can always be promoted, range space is allowed to change
promotedomainspace(D::Multiplication,sp::AnySpace)=D
promotedomainspace(D::Multiplication,sp::FunctionSpace)=Multiplication(D.f,sp)


