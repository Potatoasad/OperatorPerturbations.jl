import SymbolicUtils: Postwalk, Fixpoint, Prewalk, PassThrough

function partial_reorder(main_list::Vector, symmetry::Vector; by=identity)
	reorder = symmetry[sortperm(main_list[symmetry]; by=by)]
	result = collect(1:length(main_list))
	result2 = 1:length(main_list)
	for i ∈ 1:length(symmetry)
		if symmetry[i] != reorder[i]
			result[symmetry[i]] = result2[reorder[i]]
		end
	end
	main_list[result]
end

function partial_reorder(main_list::Vector, symmetry_list::Vector{Vector{T}}; by=identity) where {T}
	p = main_list
	for symmetry in symmetry_list
		p = partial_reorder(p, symmetry; by=by)
	end
	p
end


already_partially_ordered(x; by=hash) = true
function already_partially_ordered(x::Term{NewTensor}; by=hash)
	if !is_symmetric(x)
		return true
	end
	args = arguments(x)
	sym_inds = symmetric_indices(Slots(x))
	ordered_args = sort(args; by=hash)
	for i in 1:length(args)
		if by(args[i]) != by(ordered_args[i])
			return false
		end
	end
	return true
end

canonicalize_term(x; by=hash) = x
function canonicalize_term(x::Term{NewTensor}; by=hash)
	args = partial_reorder(arguments(x),symmetric_indices(Slots(x));by=by)
	similarterm(x,operation(x),args)
end

r = @rule ~x::(z -> !already_partially_ordered(z)) => canonicalize_term(x)
canonicalize(x) = simplify(x, Prewalk(PassThrough(r)))

export(canonicalize)