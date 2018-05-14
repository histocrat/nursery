
describe 'futures example' do

	class Future < BasicObject

		attr_accessor :result

		def initialize(nursery, &job)
			@child = nursery.run { job[self] }
			@loaded = false
		end

		def load
			@child.finish unless @loaded
			@loaded = true
		end

		def method_missing(m, *args, &blk)
			self.load
			result.public_send(m, *args, &blk)
		end

	end

	it 'lets you pass around the result of an async call' do

		eventually_8 = []		

		Nursery.with_nursery do |nursery|

			eventually_3 = Future.new(nursery) { |future| do_something_expensive; future.result = 3 }

			eventually_4 = Future.new(nursery) { |future| do_something_expensive; future.result = 4 }

			nursery.run { eventually_8 << (eventually_3 + eventually_4 + 1) }

		end

		expect(eventually_8).to eq([8])

	end
end
