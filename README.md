# Amqp

This module for Elixir makes working with AMQP and RabbitMQ a little easier.

Getting Started
===============

Connecting with this module is fairly simple:

	server = Amqp.Server url: 'amqp://guest:guest@localhost:5672/test'
	server = server.connect

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

TODO
====

I'm going to add a number of common behaviors to the list of submodules:

* Producer - just sends messages
* Consumer - just receives messages
* Pipe - receives a message on one exchange and sends to another
* Filter - receives messages on one exchange and selectively sends to another
* Translator - receives a message in one format and sends to another exchange in another format 
* and many more...



