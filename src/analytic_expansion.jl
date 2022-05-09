abstract type AbstractAnalyticOperator <: AbstractSlotStructure end

# at the moment assume complete analyticity over all non perturbative slots
struct AnalyticOperator <: AbstractAnalyticOperator 
	indices::Vector{Int64}
end

struct OperatorExpansion <: AbstractSlotStructure
	order::Vector{Int64}
end

is_expansion(x) = false
is_expansion(x::Slots) = Type{OperatorExpansion} ∈ keys(x.slot_structures)
is_expansion(x::Term{NewTensor}) = is_expansion(Slots(x))
	
expansion_order(x) = (nothing,)
expansion_order(x::Slots) = x.slot_structures[Type{OperatorExpansion}].order
expansion_order(x::Term{NewTensor}) = expansion_order(Slots(x))

order_match(x, order::Union{Tuple,Vector}) = all(expansion_order(x) .== order)

is_analytic(x::Slots) = Type{AnalyticOperator} ∈ keys(x.slot_structures)
is_analytic(x::Term{NewTensor}) = is_analytic(Slots(x))
analytic_indices(x::Slots) = x.slot_structures[Type{AnalyticOperator}].indices

is_an_Add(x::Add) = true
is_an_Add(x) = false
should_expand_analytic(x) = false
function should_expand_analytic(x::Term{NewTensor})
	if !is_analytic(x)
		return false
	end
	any(is_an_Add.(arguments(x)))
end

fixed_order_term(a::Vector,b::Union{Vector{Int},Tuple}) = Iterators.flatten([collect(repeat([a[i]],b[i])) for i ∈ 1:length(b)]) |> collect

function all_combs(target_order, n_slots)
	a = Iterators.product(repeat([0:target_order],n_slots)...) |> collect
	[collect(i) for i ∈ vcat(a...) if sum(i) ≤ target_order]
end

is_zero(x::Number) = (x == 0)
is_zero(x::Union{Sym,Add,Mul,Term,Pow}) = false

function is_zero_at_this_order(args::Vector, order::Vector{Int})
	inds = findall(x -> x != 0, order)
	any(is_zero.(args[inds]))
end

function order_to_symmetry(order)
	n = 1:sum(order)
	y = cumsum(order)
	[collect((i-1 == 0 ? 1 : y[i-1]+1):y[i]) for i ∈ 1:(length(y))]
end

function make_expanded_term_like(old::Term{NewTensor}, args::Vector, order::Vector{Int}; Linearity=Multilinear, Symmetry=TotalSymmetry, OperatorExpansion=OperatorExpansion)
	F = operation(old)
	display = TensorDisplay(old)
	new_display = append_sup(display, "$(order)")
	old_slot_struct = Slots(old)
	new_slot_number = sum(order)
	NewSlotStructureNeeded = Slots{new_slot_number}(
		Multilinear(collect(1:new_slot_number)),
		TotalSymmetry(order_to_symmetry(order)),
		OperatorExpansion(order)
	)
	NewSlotStructureNeeded = merge_together(old_slot_struct, NewSlotStructureNeeded)
	remove_structure!(NewSlotStructureNeeded, Type{AnalyticOperator})
	new_metadata = Base.ImmutableDict(Type{Slots} => NewSlotStructureNeeded)
	new_metadata = merge(F.metadata, new_metadata)
	F_new = operator(new_display, NewSlotStructureNeeded, new_metadata)
	F_new(fixed_order_term(args,order)...)
end

order_seperate(x::Add, Ξ::APT) = seperate_orders(x,Ξ)
order_seperate(x::Union{Mul,Term,Sym,Pow}, Ξ::APT) = Dict([Tuple(pert(x,Ξ)) => x])

function seperate_zeroth_and_higher(x::Union{Add,Mul,Term,Sym,Pow},Ξ::APT)
	ords = order_seperate(x,Ξ)
	zeroth = get(ords,(0,0),0)
	non_zeroth = x - zeroth
	(zeroth,non_zeroth)
end
seperate_zeroth_and_higher(Ξ::APT) = (x -> seperate_zeroth_and_higher(x,Ξ))
	
function analytic_expand_term(x::Term{NewTensor}, total_order::Int, Ξ::APT)	
	N_slots = number_of_slots(x)
	F = operation(x)
	args = arguments(x)
	terms = seperate_zeroth_and_higher(Ξ).(expand.(arguments(x)))
	zeroth_args = [a[1] for a in terms]
	new_args = [a[2] for a in terms]
	all_extra_terms = [make_expanded_term_like(x, new_args, order) for order ∈ all_combs(total_order, N_slots) if (sum(order) != 0) && !(is_zero_at_this_order(new_args,order))]
	if length(all_extra_terms) == 0
		linear_terms = 0
	else
		linear_terms = sum(all_extra_terms)
	end
	return F(zeroth_args...) + linear_terms
end
analytic_expand_term(Ξ::APT, total_order::Int) = (x -> analytic_expand_term(x, total_order, Ξ))


r2(Ξ::APT, total_order::Int) = @rule ~x::(z -> should_expand_analytic(z)) => analytic_expand_term(x,total_order,Ξ)

expand_analytic(x, Ξ::APT, total_order::Int) = simplify(x,Prewalk(PassThrough(r2(Ξ, total_order))))

expand_analytic(Ξ::APT, total_order::Int) = (x -> expand_analytic(x, Ξ, total_order))


export(AnalyticOperator, expand_analytic, OperatorExpansion)