defrecord Amqp.Producer, amqp: nil do
	def start(uri,self) do
		self.amqp(Amqp.Server.new.connect(uri))
	end
	def send(message,self) do
		self.amqp.send self.amqp.uri.exchange, self.amqp.uri.key, message
	end
end
