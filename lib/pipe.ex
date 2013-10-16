defrecord Pipe, amqp: nil do
	def start(uri,fun,self) do
		self = self.amqp(Amqp.Server.new.connect(uri))
		self.amqp.receive(self.amqp.uri.exchange, self.amqp.uri.key, self.amqp.uri.queue)
		self.amqp.wait fn(message,properties) ->
			self.amqp.send(self.amqp.uri.destination,self.amqp.uri.route, fun.(message,properties))
		end	
	end
end
