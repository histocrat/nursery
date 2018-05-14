class Nursery
	class Child

		attr_reader :nursery
		attr_reader :thread
		attr_reader :config

		def initialize(nursery, config, job)
			@nursery = nursery
			@thread = Thread.new(&job)
			@thread[:nursery] = nursery
			@config = config
		end

		def finish
			thread.join unless self.thread == Thread.current
			nil
		rescue CancelledJob
			nil
		rescue Exception
			raise unless @config[:swallow_exceptions]
		end

	end

	class <<self
		attr_accessor :child_class
	end

	@child_class = Child
end
