The goal of the [Nursery pattern](https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/) is to make it clearly defined when a given concurrent process may still be running, without limiting your ability to use more advanced patterns.

To this end, we use both a Nursery block and a Nursery object, as follows:

```ruby

Nursery.with_nursery do |nursery|

	# Sync stuff works as normal
	Foo.bar()

	# Async processes are spawned by calling .run on the object that's been passed into the with_nursery block
	nursery.run do
		# async stuff happens here
	end
	nursery.run { more async stuff }
	nursery.run(&async_proc)

	# Other concurrency patterns can be used by passing in the nursery object
	future = Future.new(nursery, &remote_service_query)

end
```

A `Nursery.with_nursery` block starts executing immediately, and will not finish (code won't pass the `end`) until every child process it's spawned has completed, even if an error is thrown. If your child processes include checkpoints, it's possible to stop their execution early. This allows a child to be cancelled from another child, or by the parent process, or implicitly on error. You can write checkpoints explicitly, like this:

```ruby

def poll
	loop do
		$queue.read
		Nursery.checkpoint
		sleep(1)
	end
end

```

or, if you have a class that will be frequently called inside async blocks, you can annotate its methods as checkpoints, and a checkpoint will be inserted before each one is invoked.

```ruby

class AsyncFriendly

	extend Nursery::Annotations

	checkpoint def add(x,y)
		x+y
	end

	checkpoint def subtract(x,y)
		x-y
	end

end
```

Nursery.checkpoint can take itself a block. If a block is passed, it will be executed if and when the block is cancelled at the checkpoint. This is useful if an asynchronous task needs to be able to do some cleanup to exit gracefully.

After completing, a `with_nursery` block will raise an exception if an exception was raised in any async job. You can override this behavior by passing `swallow_exceptions` to either the `with_nursery` or `run` methods.

By default, Nursery uses the Nursery::Child class as its async handler, which simply delegates to `Thread.new()`. This means that `run` blocks inherit scope from their surroundings, which is usually what you want. If you'd like to use a fancier method of handling asynchronous calls (such as Rails's ActiveJob) or force things to be single-threaded in your testing or dev environment, you can create your own handler class and inject it into the Nursery as follows:

```ruby

Nursery.child_class = SynchronousRunner

```

Your handler class must define an `initialize(nursery, config, job)` method (that will generally start the job running) and a `finish` method that blocks until the job is done. The latter should handle the `Nursery::CancelledJob` exception raised by a checkpoint being hit.
