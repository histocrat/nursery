describe "simple parallelism" do

	it "runs blocks in parallel" do
		start_time = Time.now

		Nursery.with_nursery do |nursery|

			20.times { nursery.run { sleep(0.1) } }

		end

		expect(Time.now).to be_within(0.2).of(start_time)
	end

	it "can share state naively (but probably shouldn't)" do

		numbers = []

		Nursery.with_nursery do |nursery|

			1.upto(10) do |i|
				nursery.run do
					numbers << i
				end
			end
		end

		expect(numbers).to match_array( [*1..10].shuffle )

	end

	it "lets siblings cancel siblings" do

		numbers = [1,2,3]		

		Nursery.with_nursery do |nursery|

			nursery.run { loop { do_something_expensive; Nursery.checkpoint } }

			nursery.run { do_something_expensive; numbers.clear; nursery.cancel }
		end

		expect(numbers).to be_empty

	end

	it "lets siblings refer to each other" do
		Nursery.with_nursery do |nursery|

			values = [0, 1, 0, 0, 2, 5, 6]

			cleaner = nursery.run do
				values.reject! { |i| sleep(0.1); i.zero? }
			end

			nursery.run do
				sum = values.inject(:+)
				cleaner.finish
				values.each { |x| sum += 1.0/x }
				expect(15..16).to cover(sum)
			end

		end
	end

	it "ensures no task runs after the block finishes" do
		state_leaker = {}

		Nursery.with_nursery do |nursery|

			state_leaker[:nursery] = nursery
		
		end

		expect{ state_leaker[:nursery].run{ do_something_expensive } }
			.to raise_exception(RuntimeError, "Nursery#run called outside of with_nursery block")

	end

end

describe "composing with other patterns" do

	class AsyncBuilder

		attr_reader :nursery
		attr_accessor :attributes

		def initialize(nursery, &block)
			@nursery = nursery
			@attributes = {}
			instance_exec(&block)
		end

		def convert_to_value(*values)
			do_something_expensive
			values.join
		end

		def method_missing(m,*args,&block)
			nursery.run { attributes[m] = convert_to_value(*args) }
		end

	end

	it "plays well with instance_exec" do

		builder_obj = Nursery.with_nursery do |nursery|

			thing = 0

			AsyncBuilder.new(nursery) do

				llama 				:hairy
				other_llama			:hairier
				third_llama			:shorn
				thing				thing
			end

		end

		expect(builder_obj.attributes).to eq ( {llama: 'hairy', other_llama: 'hairier', third_llama: 'shorn', thing: '0'} )
	end

end
