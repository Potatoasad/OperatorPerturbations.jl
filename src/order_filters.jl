r3(p::Function) = @rule ~x::(z -> (is_expansion(z) && p(z))) => 0	
set_orders_to_zero(x, p::Function) = simplify(x,Prewalk(PassThrough(r3(p))))
set_orders_to_zero(p::Function) = (x -> set_orders_to_zero(x, p))

export(set_orders_to_zero)