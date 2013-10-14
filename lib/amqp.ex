defmodule Amqp do

	# Define record types for sending messages etc
	defrecord :amqp_params_network, Record.extract( :amqp_params_network, from: "./deps/amqp_client/include/amqp_client.hrl")
	defrecord :"basic.publish", Record.extract( :"basic.publish", from: "./deps/rabbit_common/include/rabbit_framing.hrl") 
	defrecord :"P_basic", Record.extract( :"P_basic", from: "./deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :amqp_msg, props: :"P_basic".new, payload: ""
	defrecord :"exchange.declare", Record.extract( :"exchange.declare", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"exchange.declare_ok", Record.extract( :"exchange.declare_ok", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"queue.declare", Record.extract( :"queue.declare", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"queue.bind", Record.extract( :"queue.bind", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"queue.unbind", Record.extract( :"queue.unbind", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"basic.get", Record.extract( :"basic.get", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"basic.get_ok", Record.extract( :"basic.get_ok", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"basic.get_empty", Record.extract( :"basic.get_empty", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"basic.consume", Record.extract( :"basic.consume", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"basic.consume_ok", Record.extract( :"basic.consume_ok", from: "deps/rabbit_common/include/rabbit_framing.hrl")
	defrecord :"basic.ack", Record.extract( :"basic.ack", from: "deps/rabbit_common/include/rabbit_framing.hrl" )

	# Connect to an AMQP server via URL
	defrecord Server, url: 'amqp://guest:guest@localhost:5672/', connection: nil, channel: nil, ctag: "" do
		
		# connect to the server in question
		def connect(server) do
			{ :ok, params } = :amqp_uri.parse server.url
			{ :ok, connection } = :amqp_connection.start params
			server = server.connection(connection)
			{ :ok, channel } = :amqp_connection.open_channel connection
			server = server.channel(channel)
			server
		end
	
		# Send a message to an exchange, exchange, key, and message are binaries ""
		def send(exchange,key,message,server) do
			publish = :'basic.publish'.new exchange: exchange, routing_key: key
			msg = :amqp_msg.new payload: message
			:amqp_channel.cast server.channel, publish, msg
		end

		# Binds a exchange key and queue together setting up a subscription
		def receive(exchange,key,queue,server) do
			:amqp_channel.call server.channel, :"exchange.declare".new exchange: exchange, type: "topic", auto_delete: true
			:amqp_channel.call server.channel, :"queue.declare".new queue: queue, auto_delete: true
			:amqp_channel.call server.channel, :"queue.bind".new queue: queue, exchange: exchange, routing_key: key
			{ :"basic.consume_ok", ctag } = :amqp_channel.call server.channel, :"basic.consume".new queue: queue
			server.ctag(ctag)	
		end

		def wait(callback,server) do
			receive do
				{ :"basic.consume_ok", _ctag } -> 
					server.wait(callback)
				{ { :"basic.deliver", _ctag, tag, _redelivered, exchange, key }, 
				  {:amqp_msg, {:P_basic, content_type, _content_encoding, 
						_headers, _delivery_mode, _priority, 
						_correlation_id, _reply_to, _expiration, 
						_message_id, _timestamp, _type, _user_id, 
						_app_id, _cluster_id }, payload } } ->
					:amqp_channel.cast server.channel, :"basic.ack".new delivery_tag: tag
					try do
						callback.(payload,  content_type: content_type, routing_key: key, exchange: exchange )
					after
						server.wait(callback)
					end
				any ->
					IO.puts "Unknown message #{any}"
					server.wait(callback)
			end		
		end
	end
end
