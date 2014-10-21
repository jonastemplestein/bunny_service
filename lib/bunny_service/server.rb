require "bunny"
require "pry"
require "json"

module BunnyService

  class Server

    attr_reader :logger, :connection, :exchange, :channel, :queue,
      :service_name

    def initialize(rabbit_url: nil, exchange_name:, service_name:, logger: nil)

      rabbit_url ||= ENV["RABBIT_URL"]
      logger ||= Logger.new(STDOUT)

      @connection = Bunny.new(rabbit_url).start
      # each service gets it's own channel to allow services in the same
      # process to execute requests concurrently
      @channel = connection.create_channel(nil, 16)
      @exchange = channel.direct(exchange_name)
      @service_name = service_name
      @logger = logger
      log "Initialized service"
    end

    def listen(&block)

      @queue = channel.queue(service_name).bind(
        exchange,
        routing_key: service_name
      )

      queue.subscribe do |delivery_info, properties, payload|

        request_id = properties.correlation_id
        reply_queue = properties.reply_to
        payload = BunnyService::Util.deserialize(payload)

        log "Received request #{request_id} with payload #{payload.inspect}"

        response = block.call(payload)

        log "Publishing response #{response.inspect} on queue #{reply_queue}"

        channel.default_exchange.publish(
          BunnyService::Util.serialize(response),
          routing_key: reply_queue, # default_exchange is a direct exchange
          correlation_id: request_id,
        )
      end
      log "Subscribed to queue"
      self
    end

    private

    def log(message, severity=Logger::INFO)
      logger.add(severity) {
        "[#{@service_name} service] #{message}"
      }
    end
  end
end
