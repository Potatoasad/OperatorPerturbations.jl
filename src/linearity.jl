param(s::Type{K}) where {K <: MultilinearSlotStructure} = K 
	
is_scalar(x, s::Type{<:MultilinearSlotStructure}) = true
is_scalar(x::Number, s::Type{<:MultilinearSlotStructure}) = true
is_scalar(x::Sym, s::Type{<:MultilinearSlotStructure}) = !hasmetadata(x, Type{NotScalar{param(s)}})

argument_should_expand(x::Number, s::Type{<:MultilinearSlotStructure}) = (x == one(x)) ? false : true
argument_should_expand(x::Sym, s::Type{<:MultilinearSlotStructure}) = true
argument_should_expand(x::Add, s::Type{<:MultilinearSlotStructure}) = true
argument_should_expand(x::Mul, s::Type{<:MultilinearSlotStructure}) = any((x -> is_scalar(x,s)).(arguments(x)))
argument_should_expand(s::Type{<:MultilinearSlotStructure}) = (x -> argument_should_expand(x,s))

should_expand(x,s::Type{<:MultilinearSlotStructure}) = false
should_expand(x::Term{NewTensor},s::Type{<:MultilinearSlotStructure}) = is_multilinear(x) && any(argument_should_expand(s).(arguments(x)))

function expand_additions(x,s::Type{<:MultilinearSlotStructure})
	is_scalar(x,s) ? (x,1) : (1,x)
end
function expand_additions(x::Mul, s::Type{<:MultilinearSlotStructure})
	scalars = []; non_scalars = [];
	for arg in arguments(x)
		is_scalar(arg,s) ? push!(scalars, arg) : push!(non_scalars,arg)
	end
	if length(scalars) == 0
		scalars = [1]
	end
	if length(non_scalars) == 0
		non_scalars = [1]
	end
	Tuple([operation(x)(scalars...),operation(x)(non_scalars...)])
end
make_list_if_not(x) = [x]
make_list_if_not(x::Vector) = x
expand_additions(x::Add, s::Type{<:MultilinearSlotStructure}) = (x -> expand_additions(x,s)).(arguments(x))
expand_additions(s::Type{<:MultilinearSlotStructure}) = (x -> expand_additions(x,s))

function expand_linear_term(x::Term{NewTensor}, s::Type{<:MultilinearSlotStructure})
	F = operation(x)
	arg_tuples = expand_additions(s).(expand.(arguments(x)))
	arg_tuples = make_list_if_not.(expand_additions(s).(expand.(arguments(x))))
	newstuff = Iterators.product(arg_tuples...) |> collect |> vec
	sum([prod([p[1] for p ∈ a])*F([p[2] for p ∈ a]...) for a ∈ newstuff])
end
expand_linear_term(s::Type{<:MultilinearSlotStructure}) = (x -> expand_linear_term(x,s))

r2(s::Type{<:MultilinearSlotStructure}) = @rule ~x::(z -> should_expand(z,s)) => expand_linear_term(x,s)

expand_linear(x,s::Type{<:MultilinearSlotStructure}) = simplify(x,Prewalk(PassThrough(r2(s))))

expand_linear(s::Type{<:MultilinearSlotStructure}) = (x -> expand_linear(x,s))

export expand_linear 