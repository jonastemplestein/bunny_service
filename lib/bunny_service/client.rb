require "bunny"
require "thread"
require "json"

module BunnyService
  class Client

    attr_reader :reply_queue, :lock, :condition, :options

    attr_accessor :response, :call_id

    def initialize(options={})
      @options = {
        rabbit_url: ENV["RABBIT_URL"],
        exchange_name: "amq.direct",
        logger: Logger.new(STDOUT),
      }.merge(options)

      @lock = Mutex.new
      @condition = ConditionVariable.new
      that = self

      log "Initializing client"

      # TODO lazy-initialize that. no need to create a queue if the client
      # isn't used
      reply_queue.subscribe do |delivery_info, properties, payload|
        if properties.correlation_id == that.call_id
          that.response = payload
          that.lock.synchronize{that.condition.signal}
        end
      end

      log "Subscribed to exclusive queue #{reply_queue.name}"
    end

    def call(service_name, payload={})
      raise "Payload has to be a Hash" unless payload.is_a?(Hash)

      self.call_id = BunnyService::Util.generate_uuid
      payload = BunnyService::Util.serialize(payload)
      log "[#{call_id}] Calling #{service_name} w/ #{payload})"

      exchange.publish(
        payload,
        routing_key: service_name,
        correlation_id: call_id,
        reply_to: reply_queue.name)

      lock.synchronize{condition.wait(lock)}
      log "[#{call_id}] Got response: #{response}"
      BunnyService::Util.deserialize(response)
    end

    def reply_queue
      @reply_queue ||= channel.queue("", exclusive: true)
    end

    def connection
      @connection ||= Bunny.new(options.fetch(:rabbit_url)).start
    end

    def channel
      @channel ||= connection.create_channel
    end

    def exchange
      @exchange ||= channel.direct(options.fetch(:exchange_name))
    end

    def teardown
      log "Tearing down"
      connection.close
    end

    private

    def log(message, severity=Logger::INFO)
      options.fetch(:logger).add(severity) {
        "[client #{self.object_id}] #{message}"
      }
    end
  end
end
