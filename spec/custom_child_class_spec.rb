describe 'creating your own child class' do

	class SynchronousRunner

		def initialize(nursery, config, job)
			@nursery = nursery
			@config = config
			@job = job
		end

		def finish
			@job.call
		rescue Nursery::CancelledJob
			:cancelled
		end

	end

	before do
		Nursery.child_class = SynchronousRunner
	end

	after do
		Nursery.child_class = Nursery::Child
	end

	it 'should wrap your own async mechanism' do
		expect(SynchronousRunner).to receive(:new).with(any_args).and_call_original

		Nursery.with_nursery do |nursery|
			nursery.run {}
		end

	end

end
