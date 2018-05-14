describe "cleaning up when cancelled" do

	class LockedResource

		attr_accessor :locked

		def write(str)
			raise unless locked
		end

		def with_lock
			self.locked = true
			yield
		ensure
			self.locked = false
		end

		def locked?
			@locked
		end

	end

	it 'can clean up by passing a block to #checkpoint' do
		@file = LockedResource.new

		Nursery.with_nursery do |nursery|

			nursery.run do
				@file.locked = true
				cleanup = ->{ @file.locked = false }
				loop do
					Nursery.checkpoint(&cleanup)
					@file.write('running...')
					do_something_expensive
				end
				cleanup.call
			end

			sleep(0.2)
			nursery.cancel
		end

		expect(@file).not_to be_locked
		

	end

	it 'lets methods with ensure blocks clean up after themselves' do
		@file = LockedResource.new

		Nursery.with_nursery do |nursery|

			nursery.run do
				@file.with_lock do
					loop do
						do_something_expensive
						Nursery.checkpoint
						@file.write('running...')
					end
				end
			end

			sleep(0.2)
			nursery.cancel
		end

		expect(@file).not_to be_locked

	end


end
