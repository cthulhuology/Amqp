# Amqp

This module for Elixir makes working with AMQP and RabbitMQ a little easier.

Getting Started
===============

If you're impatient, I highly recommend using the convience records:

	c = Amqp.Consumer.new.start "amqp://guest:guest@localhost:5672/myVhost/myExchange/%23/myQueue", fn( msg, props ) -> 
		IO.puts "#{msg}" 
	end

And to send the messages to the exchange:

	p = Amqp.Producer.new.start "amqp://guest:guest@localhost:5672/myVhost/myexchange/mykey"
	p.send "hello world"

Connecting with this module is fairly simple:

	server = Amqp.Server.new.connect "amqp://guest:guest@localhost:5672/test"

At this point the server will have a connection and an open channel.

In order to process incoming messages you can write code like:

	server.receive "my-exchange", "#", "my-queue"
	server.wait fn(message, properties) -> IO.puts "#{ message }" end

The receive method binds the given exchange and routing key to a specific queue,
and then subscribes the running process to that queue.  The wait method then
consumes messages as they come in, and calls the callback function on each message
as it comes in.

To send messages you can use the server record's send method:

	server.send "my-exchange", "some-key", "A message for you"

And that's about it.  Right now this code makes a few assumptions that follow 
what I've found to be best practice in large scale deployments:

* All exchanges are topic exchanges, (because you can mimic the behavior of all others with them)
* All exchanges and queues are marked auto_delete: true (because you should clean up after yourself)
* Each process only listens to a single exchange at a time (because it is easy to run more processes)

Advanced Idioms
---------------

There is more to life than sending and receiving messages, there's resending messages!  The simplest form
of resender is a pipe.  Like in plumbing, a pipe takes a stream of messages in from one end and outputs it
in another location out the other end.  Pipes need not be dumb conduits, but rather may apply an arbitrary
transform to their contents.  For example, let's say we want to generate a stream of messages that is the
lowercase normalized form of another stream.  We can use a pipe with a downcase function to normalize our
text data

	Pipe.new.start "amqp://guest:guest@localhost:5672/test/input-stream/#/lowercase-pipe/lowercase-out/pipe", 
		fn (msg,props) -> String.downcase msg end

This will take each message from the input-stream exchange and output a lower case version to the pipe-out 
exchange with one for one throughput.  You could also create a version of the same feed with the first letter
capitalized:

	Pipe.new.start "amqp://guest:guest@localhost:5672/test/lowercase-out/#/capitalize-pipe/capitalize-out/pipe", 
		fn (msg,props) -> String.capitalize msg end

Using these sorts of transforms can spread out a lot of processing across many geographically distributed nodes.



TODO
====

I'm going to add a number of common behaviors to the list of submodules:

* Filter - receives messages on one exchange and selectively sends to another
* Translator - receives a message in one format and sends to another exchange in another format 
* and many more...



