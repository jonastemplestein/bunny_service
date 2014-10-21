# bunny_service

RPC service/client implementation for rabbit mq

# Installation

Add this to your gemfile:

# Client usage

```
require "bunny_service"
conn = Bunny.new(automatically_recover: false)
conn.start
channel = conn.create_channel
exchange = ch.direct("bunny_service_example")

client = BunnyService::Client.new(channel: ch, exchange: exchange)

# Synchronously calls accounts.create on bunny_service_example exchange
client.call("accounts.create", {name: "Peter Pan"})
```

# Server usage
```
require "bunny_service"
conn = Bunny.new(automatically_recover: false)
conn.start
channel = conn.create_channel
exchange = ch.direct("bunny_service_example")

service = BunnyService::Server.new(
  channel: ch, 
  exchange: exchange,
  service_name: "accounts.create",
)

# Asynchronously listens for calls to accounts.create
service.listen do |params, context|
  # ... do stuff
  {message: "Created account for #{params["name"]}"}  
end

```

# Specs
Run `rspec` (`bundle exec rspec` depending on your setup)
