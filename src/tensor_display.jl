import SymbolicUtils: Sym, FnType, Term, Add, Mul, Pow, similarterm
using SymbolicUtils

# Create a new number type simply for dispatch purposes.
# Everytime you define a tensor manipulation system, you would define a new number type

struct NewTensor <: Number end

# Create a TensorDisplay module
abstract type AbstractTensorDisplay end

"""
This contains all the info to display a tensor 
"""
struct TensorDisplay{T <: AbstractString} <: AbstractTensorDisplay
	name::T
	sub::T
	sup::T
end

TensorDisplay(name::AbstractString; sub="", super="") = TensorDisplay(name,sub,super)
append_sub(x::TensorDisplay,a::AbstractString) = TensorDisplay(x.name,x.sub*a,x.sup)
append_sub(a::AbstractString) = (x -> append_sub(x,a))
append_sup(x::TensorDisplay,a::AbstractString) = TensorDisplay(x.name,x.sub,x.sup*a)
append_sup(a::AbstractString) = (x -> append_sup(x,a))
append_name(x::TensorDisplay,a::AbstractString) = TensorDisplay(x.name*a,x.sub,x.sup)
append_name(a::AbstractString) = (x -> append_name(x,a))

"""
Function to extract the latex representation of the TensorDisplay as a string. 
ex: str(TensorDisplay("T","a","\\textrm{int}")) = "T_{a}^{\textrm{int}}"
"""
function str(x::TensorDisplay)
	sub = x.sub == "" ? "" : "_{$(x.sub)}"
	sup = x.sup == "" ? "" : "^{$(x.sup)}"
	"$(x.name)$(sup)$(sub)" 
end
str(x::AbstractString) = x
subscript(x::TensorDisplay) = x.sub
superscript(x::TensorDisplay) = x.sup
name(x::TensorDisplay) = x.name

# Define the Display properties of the NewTensor type
TensorDisplay(x::Term{NewTensor}) = getmetadata(operation(x),Type{TensorDisplay})
subscript(x::Term{NewTensor}) = TensorDisplay(x).sub
superscript(x::Term{NewTensor}) = TensorDisplay(x).sup
name(x::Term{NewTensor}) = TensorDisplay(x).name

# utility function
intersperse(a::Vector; token = ",") = [(i % 2) == 0 ? token : a[i÷2 + 1] for i ∈ 1:(2*length(a)-1)]


export TensorDisplay, NewTensor