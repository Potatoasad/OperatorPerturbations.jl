
abstract type PerturbationOrder end

abstract type AbstractPerturbationParameters{T} end

const APT{T} = AbstractPerturbationParameters{T} where {T}

struct PerturbationParameters{T} <: AbstractPerturbationParameters{T}
	type_list::Vector{DataType}
	params::Vector{T}
end

PerturbationParameters(x::Dict{DataType, T}) where {T} = PerturbationParameters(collect(keys(x)),collect(values(x)))


pert(x, p::DataType)::Integer = 0
pert(x::Sym, p::DataType)::Integer = hasmetadata(x, p) ? getmetadata(x, p) : 0
pert(x::Mul, p::DataType)::Integer = sum(pert(a, p) for a ∈ arguments(x))
pert(x::Pow, p::DataType)::Integer = pert(x.base, p)*x.exp
pert(x, ps::Vector{DataType}) = [pert(x, p) for p ∈ ps]
pert(x, Ξ::APT) = [pert(x, p) for p ∈ Ξ.type_list]
pert(Ξ::APT) = (x -> pert(x,Ξ))
pert(x, pss::Vector{Sym}) = pert(x, [collect(keys(p.metadata)) for p in pss])

filter(x::Add, p::DataType, i::Integer) = similarterm(x, operation(x), [a for a in arguments(x) if pert(a,p) == i])

filter(x::Add, ps::Vector{DataType}, i_vec::Vector{<:Integer}) where {T <: PerturbationOrder} = similarterm(x, operation(x), [a for a in arguments(x) if all((pert(a,p) == i) for (i,p) ∈ zip(i_vec, ps))])

pert_like(x::Union{Tuple,Vector},Ξ::APT) = prod((Ξ.params[i]^x[i] for i ∈ 1:length(Ξ.params)))

divide_if_Add(x::Add, divisor) = similarterm(x,operation(x),arguments(x).//divisor)
divide_if_Add(x, divisor) = x//divisor

#arguments_general(x::Union{Add,Mul,Pow}) = arguments(x)
#arguments_general(x::Sym) = [x]
seperate_orders(x::Sym,ps::Union{APT,Vector{DataType},DataType}) = Dict([Tuple(pert(x,ps)) => x])
function seperate_orders(x::Union{Add,Mul,Pow}, ps::Union{APT,Vector{DataType},DataType}; divide=false) 
	new = expand(x)
	# Need a general dictionary that can hold lots of different types
	if divide
		thedicts = [Dict{Tuple{Number,Number},Union{Add,Mul,Pow,Sym,Term}}([Tuple(pert(a,ps)) => divide_if_Add(a,pert_like(pert(a,ps),ps))]) for a ∈ arguments(new)]
	else
		thedicts = [Dict{Tuple{Number,Number},Union{Add,Mul,Pow,Sym,Term}}([Tuple(pert(a,ps)) => a]) for a ∈ arguments(new)]
	end
	final_dict = merge(operation(x), thedicts...)
	final_dict
end
seperate_orders(ps::Union{APT,Vector{DataType},DataType}; divide=false) = (x->seperate_orders(x,ps;divide=divide))

export(seperate_orders)