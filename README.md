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
  - You have to run the `BunnyService::Server` first. RabbitMQ discards messages with no matching bindings and `BunnyService::Server` sets up the bindings and queues 
  - The RabbitMQ web interface is super useful for debugging services. You should be able to inspect exchanges, queues, bindings, running consumers, waiting messages (you can dequeue and immediately re-enqueue) and even send requests to the services.

About concurrency:

 - Bunny channels must not be shared between threads. That leads to non-deterministic mayhem (see http://rubybunny.info/articles/concurrency.html for an explanation)

 - Each client/server creates its own connection (`Bunny::Session`). Each of those connections forks a networking thread. For details see http://rubybunny.info/articles/connecting.html

 - Each bunny connection (`Bunny::Session`) creates a separate networking IO thread

 - Each server channel has a threadpool, the size of which determines the number of concurrent requests a single server process can respond to

# Exception handling

http://rubybunny.info/articles/error_handling.html

### Fault tolerance


# Further reading

The bunny docs are very well written and worth reading: http://rubybunny.info/articles/guides.html

# TODO

 - do we care about message order?
 - why do we have to send the callback messages to an exclusive queue on the _default exchange_?
 - how do we manage our services? queues and bindings need to be set up, perhaps we want to broadcast other service properties such as retry policies, as well
 - handle exceptions properly
 - properly handle logging
 - implement timeouts (currently the client waits forever)
 - retry failed services?
 - make sure specs clean up before/after they run and can't leave garbage lying around that messses with other tests
 - make sure all rabbitmq structures used for specs are torn down after suite
 - make sure the exchange, channel, queue and message properties are set correctly for our use-case
 - implement `ServiceLoader` or similar that takes a plain service object and sets up the necessary BunnyService::Servers etc
 - talk to RabbitMQ using TLS
 - should we try to implement multi-step services? the first request could enqueue another request with the same correlation id, which would then send the finished result to the waiting service client

 - do we want messages to be persistent or mandatory?
 - when do we send message acknowledgements


# Specs
Run `guard` (`bundle exec rspec` depending on your setup).

Run `guard` to continuously run specs.
