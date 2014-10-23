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
        consumer_pool_size: 2,
      }.merge(options)

      log "Initialized service"
    end

    def listen(&block)
      queue.bind(
        exchange,
        routing_key: options.fetch(:service_name)
      )

      log "Bound queue to exchange"

      queue.subscribe do |delivery_info, properties, payload|
        begin
          log "Received request #{properties.correlation_id} w/ #{payload}"

          publish_response(
            response: block.call(BunnyService::Util.deserialize(payload)),
            reply_queue: properties.reply_to,
            request_id: properties.correlation_id,
          )
        rescue StandardError => e
          publish_response(
            response: { error: e.message },
            reply_queue: properties.reply_to,
            request_id: properties.correlation_id,
          )
        end
      end

      log "Subscribed to queue"
      self
    end

    def publish_response(response:, reply_queue:, request_id:)
      if reply_queue
        log "Publishing response #{response.inspect} on queue #{reply_queue}"

        response_exchange.publish(
          BunnyService::Util.serialize(response),
          persistent: false,
          mandatory: false,
          routing_key: reply_queue,
          correlation_id: request_id,
        )
      else
        log "Not publishing response #{response.inspect} because there is no reply queue"
      end
    end

    def connection
      @connection ||= Bunny.new(options.fetch(:rabbit_url)).start
    end

    def channel
      @channel ||= connection.create_channel(
        nil,
        options.fetch(:consumer_pool_size)
      )
    end

    def exchange
      @exchange ||= channel.direct(
        options.fetch(:exchange_name),
        durable: false,
      )
    end

    def response_exchange
      @response_exchange ||= channel.default_exchange
    end

    def queue
      @queue ||= channel.queue(
        options.fetch(:service_name),
        durable: false,
      )
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
