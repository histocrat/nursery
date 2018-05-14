# Nursery

[Notes on structured concurrency, or: Go statement considered harmful](https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/) argues for a specific pattern for asynchronous operations: nurseries. A nursery is created within a code block and can spawn children that run asynchronous tasks that are guaranteed to be complete by the time the code block ends, no matter how much indirection you're using. The nursery pattern is implemented in the Python library [Trio](https://trio.readthedocs.io/en/latest/index.html).

If this pattern takes over the world, we'll need it in Ruby too. This gem implements the Nursery pattern at a high level. By default it uses Ruby's native concurrency handling.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nursery'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nursery

## Usage

```ruby
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
```

See specs for examples

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nursery. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Nursery project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/nursery/blob/master/CODE_OF_CONDUCT.md).
