defrecord Amqp.Consumer, amqp: nil do
	def start(uri,fun,self) do
		self = self.amqp(Amqp.Server.new.connect(uri))
		self.amqp.receive(self.amqp.uri.exchange, self.amqp.uri.key, self.amqp.uri.queue)
		self.amqp.wait fun
	end
end
