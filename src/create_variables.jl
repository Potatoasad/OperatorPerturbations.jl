import Symbolics: _toexpr

###### Generate a Sym with custom metadata and any display style
variable(s::AbstractString) = Sym{Number}(Symbol(s))
function variable(s::AbstractString, x::Dict{DataType,S}) where S
	var = variable(s)
	for (t,p) ∈ x
		var = setmetadata(var, t, p)
	end
	var
end
variable(s::Union{AbstractString,TensorDisplay}, x::Pair{DataType, S}) where {K,S} = setmetadata(variable(str(s)), x.first, x.second)


###### Generate a new symbolic function with custom metadata and display style
operator(s::TensorDisplay, K::Slots{N}) where {N} = setmetadata(setmetadata(Sym{FnType{NTuple{N,Number},NewTensor}}(Symbol(str(s))), Type{TensorDisplay}, s),Type{Slots},K)
operator(s::TensorDisplay, K::Slots, x::Pair{DataType, S}) where {S} = setmetadata(operator(s),x.first, x.second)

function operator(s::TensorDisplay, sl::Slots, x::Union{Dict{DataType,S},Base.ImmutableDict{DataType,S}}) where {S}
	op = operator(s,sl)
	for (t,p) ∈ x
		op = setmetadata(op, t, p)
	end
	op
end

# Overload the _toexpr function in Symbolics to have this custom tensor term
# display as you want it
function _toexpr(x::Term{NewTensor})
	is_linear = is_fully_multilinear(x)
	b = is_linear ?  ["[","]"] : ["(",")"]
	Expr(:latexifymerge, operation(x),b[1], intersperse(arguments(x))..., b[2])
end

export variable, operator