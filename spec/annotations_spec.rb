require 'nursery/annotations'

describe Nursery::Annotations do

	it "allows designating methods as checkpoints" do

		class AsyncFriendly
			extend Nursery::Annotations

			checkpoint def add(x,y)
				x+y
			end

			checkpoint def subtract(x,y)
				x-y
			end

		end

		numbers = []

		Nursery.with_nursery do |nursery|

			nursery.run do
				(1..Float::INFINITY).each { |i| (numbers << AsyncFriendly.new.add(i,i)) if rand < 0.00001 }
			end

			numbers << AsyncFriendly.new.subtract(1,1)

			do_something_expensive

			nursery.cancel

		end

		expect(numbers).not_to be_one
		expect(numbers).to include(0)

	end

end
