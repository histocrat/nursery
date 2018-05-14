describe 'errors raised by children' do

	Oops = Class.new(StandardError)

	it 'defers handling exceptions until the end of the with_nursery block' do

		tasks_completed = []

		flow = Proc.new do
			Nursery.with_nursery do |nursery|
				nursery.run { raise Oops.new; tasks_completed << 1 }

				nursery.run { tasks_completed << 2 }

				tasks_completed << 3				
			end

		end

		expect(&flow).to raise_exception(Oops)

		expect(tasks_completed).to match_array([2,3])		
		
	end

	it 'raises early if .finish is called' do

		tasks_completed = []

		flow = Proc.new do
			Nursery.with_nursery do |nursery|
				bad_child = nursery.run { raise Oops.new; tasks_completed << 1 }

				nursery.run { bad_child.finish; tasks_completed << 2 }

				tasks_completed << 3
			end

		end

		expect(&flow).to raise_exception(Oops)

		expect(tasks_completed).to match_array([3])

	end

	it 'does not raise if :swallow_exceptions is set' do

		tasks_completed = []

		flow = Proc.new do
			Nursery.with_nursery(swallow_exceptions: true) do |nursery|
				nursery.run { raise Oops.new; tasks_completed << 1 }

				nursery.run { tasks_completed << 2 }

				tasks_completed << 3
			end

		end

		expect(&flow).not_to raise_exception

		expect(tasks_completed).to match_array([2,3])
	end

end
