class Nursery

	module Annotations
		def checkpoint(method_name)
			alias_method(:"#{method_name}_without_checkpoint", method_name)
			define_method(method_name) do |*args, &blk|
				Nursery.checkpoint
				send(:"#{method_name}_without_checkpoint", *args, &blk)
			end
		end
	end

end
