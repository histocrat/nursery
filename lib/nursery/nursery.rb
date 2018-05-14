class Nursery

	attr_reader :children, :cancelled, :finished, :default_config

	CancelledJob = Class.new(StandardError)

	def initialize(default_config = {})
		@children = []
		@cancelled = false
		@finished = false
		@default_config = default_config
	end

	def run(config = default_config, &job)
		Nursery.checkpoint
		raise("Nursery#run called outside of with_nursery block") if finished
		child = self.class.child_class.new(self, config, job)
		children << child
		child
	end

	def finish
		exceptions = children.map do |child|
			begin
				child.finish
				nil
			rescue Exception => e
				e
			end
		end.compact
		exceptions.each { |e| raise(e) }
		@finished = true
	end

	def cancel
		@cancelled = true
		finish		
	end

	def self.with_nursery(config = {}, &block)
		nursery = new(config)
		begin
			retval = block.call(nursery)
		rescue StandardError
			nursery.cancel
			raise
		end
		nursery.finish
		retval
	end

	def self.checkpoint
		if Thread.current[:nursery] && Thread.current[:nursery].cancelled
			yield if block_given?
			raise CancelledJob
		end
	end

end
