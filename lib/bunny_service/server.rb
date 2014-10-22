require "bunny"
require "pry"
require "json"

module BunnyService

  class Server

    attr_reader :options

    def initialize(options={})
      @options = {
        rabbit_url: ENV["RABBIT_URL"],
        exchange_name: "amq.direct",
        logger: Logger.new(STDOUT),
        thread_pool_size: 2,
      }.merge(options)
      log "Initialized service"
    end

    def listen(&block)

      queue.bind(
        exchange,
        routing_key: options.fetch(:service_name)
      )

      queue.subscribe do |delivery_info, properties, payload|

        request_id = properties.correlation_id
        reply_queue = properties.reply_to
        payload = BunnyService::Util.deserialize(payload)

        log "Received request #{request_id} with payload #{payload.inspect}"

        response = block.call(payload)

        if reply_queue
          log "Publishing response #{response.inspect} on queue #{reply_queue}"

          channel.default_exchange.publish(
            BunnyService::Util.serialize(response),
            routing_key: reply_queue, # default_exchange is a direct exchange
            correlation_id: request_id,
          )
        else
          log "Not publishing response #{response.inspect} because there is no reply queue"
        end
      end
      log "Subscribed to queue"
      self
    end

    def connection
      @connection ||= Bunny.new(options.fetch(:rabbit_url)).start
    end

    def channel
      @channel ||= connection.create_channel(
        nil,
        options.fetch(:thread_pool_size)
      )
    end

    def exchange
      @exchange ||= channel.direct(options.fetch(:exchange_name))
    end

    def queue
      @queue ||= channel.queue(options.fetch(:service_name))
    end

    def teardown
      log "Tearing down"
      connection.close
    end

    private

    def log(message, severity=Logger::INFO)
      options.fetch(:logger).add(severity) {
        "[#{options.fetch(:service_name)} service] #{message}"
      }
    end
  end
end
