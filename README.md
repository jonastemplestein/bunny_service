# bunny_service

RPC service/client implementation for RabbitMQ.

# Installation

Add this to your Gemfile:

```
gem "bunny_service", github: "jonashuckestein/bunny_service"
```

In development, use 

```
gem "bunny_service", path: "../bunny_service"
```

# Server usage
```ruby
require "bunny_service"

sleep_service = BunnyService::Server.new(
  exchange_name: "example",
  service_name: "lazy.sleep",
)

# Asynchronously listens for calls to lazy.sleep
sleep_service.listen do |payload|
  sleep(payload["duration"].to_i)
  {message: "Slept for #{payload["duration"]} seconds"}  
end

```

# Client usage

```ruby
require "bunny_service"

client = BunnyService::Client.new(
  exchange_name: "example",
)

# Synchronously calls lazy.sleep service on the 'example' exchange.
# Should return {message: "Slept for 5 seconds"}
client.call("lazy.sleep", {duration: 5})

```

# Design
`client = BunnyService::Client.new(exchange_name:)` sets up a service client that you can use to synchronously call services through RabbitMQ. 
`exchange` needs to be a direct exchange. Each client instance creates an exclusive queue on the default exchange (TODO: figure out why it has to be on the default exchange) to listen for responses.

`client.call(service_name, payload)` sends a message to the exchange using `service_name` as the routing key and JSON-encoded payload as the body. For example,  `client.call("test_service.sleep", {duration: "5"})` will send a message with routing key "test_service.sleep" and body {"duration":"5"}. It then blocks and waits for a response message on from the exclusive queue that was set up upon initialization.

Some more notes:

  - `payload` in `service_client.call(service_name, payload)` and the response should be hashes

  - You have to run the `BunnyService::Server` before you can call the service from clients. RabbitMQ discards messages with no matching bindings and `BunnyService::Server` sets up the bindings and queues 

  - The RabbitMQ web interface is super useful for debugging services. You should be able to inspect exchanges, queues, bindings, running consumers, waiting messages (you can dequeue and immediately re-enqueue) and even send requests to the services.
  
  - Once requests are enqueued, you have to consider them to be executed successfully, even if you don't hear back. There is no way to recall a request after it was sent.

  - Neither the queue, exchange or messages are persistent. If the broker goes down, the service calls would time out anyway

About concurrency:

 - Clients can not be used simultaneously in different threads. Bunny channels must not be shared between threads. That leads to non-deterministic mayhem (see http://rubybunny.info/articles/concurrency.html for an explanation)

 - Each client/server creates its own connection (`Bunny::Session`). Each of those connections forks a networking thread. For details see http://rubybunny.info/articles/connecting.html

 - Each server channel has a threadpool, the size of which determines the number of concurrent requests a single server process can respond to. The client subscription doesn't has a threadpool because it only ever needs to process one message

- Subscription callbacks get executed in the connection's networking thread


# Exception handling

http://rubybunny.info/articles/error_handling.html

### Fault tolerance / failure scenarios

TODO think hard about what all can go wrong.

# Further reading

The bunny docs are very well written and worth reading: http://rubybunny.info/articles/guides.html

# TODO / open questions

 - Implement a rich payload format for api-services that encapsulates an actual http request

 - Use protobuf for communication

 - Does it make sense to give services an interface to acknowledge messages manually?

 - How do we manage our services? Queues and bindings need to be set up, perhaps we want to broadcast other service properties such as retry policies, as well

 - Instrument and monitor all service calls

 - Make sure specs clean up before/after they run and can't leave garbage lying around that messses with other tests

 - Implement a deadletter queue that handles errors

 - Talk to RabbitMQ using TLS

 - Use a headers exchange instead of a direct exchange

 - How do we set TTL in RabbitMQ?

 - Catch exceptions in consumer thread on client side

# Specs
Run `guard` (`bundle exec rspec` depending on your setup).

Run `guard` to continuously run specs.
