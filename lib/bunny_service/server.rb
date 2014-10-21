require "bunny"
require "pry"
require "json"

module BunnyService

  class Server

    def initialize(channel:, exchange:, service_name:)
      @channel = channel
      @exchange = exchange
      @service_name = service_name
    end

    def listen(&block)
      @queue = @channel.queue(@service_name).bind(
        @exchange,
        routing_key: @service_name
      )

      puts "[server][#{@service_name} service] initializing server"

      @queue.subscribe do |delivery_info, properties, payload|
        payload = deserialize(payload)

        response = block.call(payload)

        puts "[server][#{@service_name} service] received rpc call with params #{payload.inspect}"
        puts "[server][#{@service_name} service] response: #{response}"

        @channel.default_exchange.publish(
          serialize(response),
          routing_key: properties.reply_to,
          correlation_id: properties.correlation_id
        )

      end
      puts "[server][#{@service_name} service] subscribed to queue"
    end

    def serialize(data)
      JSON.dump(data)
    end

    def deserialize(string)
      JSON.load(string)
    end
  end
end
