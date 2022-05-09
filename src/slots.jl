
###### Define Slots
abstract type AbstractSlot end
struct Slot <: AbstractSlot end

abstract type AbstractSlotStructure end

struct Slots{N}
	slot_structures::Dict{DataType, AbstractSlotStructure}
end
Slots{N}(x::AbstractSlotStructure...) where {N} = Slots{N}(Dict([Type{typeof(x1)} => x1 for x1 in x]))
number_of_slots(x::Slots{N}) where {N} = N
slot_structure(x::Slots) = x.slot_structures
merge_together(x::Slots{N}, y::Slots{M}) where {N,M} = Slots{M}(merge(x.slot_structures,y.slot_structures))
remove_structure!(x::Slots, v::DataType) = delete!(x.slot_structures, v)


###### Multilinear Slots
abstract type MultilinearSlotStructure <: AbstractSlotStructure end

struct Multilinear <: MultilinearSlotStructure
	indices::Vector{Int64}
end

struct NotScalar{T <: MultilinearSlotStructure} end 
	
is_multilinear(x::Slots) = Type{Multilinear} ∈ keys(x.slot_structures)
multilinear_indices(x::Slots) = x.slot_structures[Type{Multilinear}].indices
is_fully_multilinear(x::Slots{N}) where {N} = is_multilinear(x) && (Set(multilinear_indices(x)) == Set(1:N))

###### Symmetric Slots
abstract type SymmetrySlotStructure <: AbstractSlotStructure end
	
struct TotalSymmetry <: SymmetrySlotStructure
	indices::Vector{Vector{Int64}}
end


is_symmetric(x::Slots) = Type{TotalSymmetry} ∈ keys(x.slot_structures)
symmetric_indices(x::Slots) = x.slot_structures[Type{TotalSymmetry}].indices
is_symmetric(x::Term{NewTensor}) = is_symmetric(Slots(x))



###### Methods for NewTensor type
is_multilinear(x::Term{NewTensor}) = is_multilinear(Slots(x))
is_fully_multilinear(x::Term{NewTensor}) = is_fully_multilinear(Slots(x))

Slots(x::Term{NewTensor}) = getmetadata(operation(x),Type{Slots})
	
number_of_slots(x::Term{NewTensor}) = number_of_slots(Slots(x))


export Slots, number_of_slots, TotalSymmetry, SymmetrySlotStructure, Multilinear, MultilinearSlotStructure