require "bunny"
require "thread"
require "json"

module BunnyService
  class Client
    attr_reader :reply_queue, :logger, :lock, :condition
    attr_accessor :response, :call_id

    def initialize(connection:, exchange_name:, logger: Logger.new(STDOUT))
      @connection = connection
      @channel = connection.create_channel
      @exchange = @channel.direct(exchange_name)
      @logger = logger

      @reply_queue = @channel.queue("", exclusive: true)

      @lock = Mutex.new
      @condition = ConditionVariable.new
      that = self

      log "Initializing client"

      @reply_queue.subscribe do |delivery_info, properties, payload|
        if properties.correlation_id == that.call_id
          that.response = payload
          that.lock.synchronize{that.condition.signal}
        end
      end

      log "Subscribed to exclusive queue #{@reply_queue.name}"
    end

    def call(service_name, payload={})
      raise "Payload has to be a Hash" unless payload.is_a?(Hash)

      self.call_id = BunnyService::Util.generate_uuid
      payload = BunnyService::Util.serialize(payload)
      log "[#{call_id}] Calling #{service_name} w/ #{payload})"

      @exchange.publish(
        payload,
        routing_key: service_name,
        correlation_id: call_id,
        reply_to: @reply_queue.name)

      lock.synchronize{condition.wait(lock)}
      log "[#{call_id}] Got response: #{response}"
      BunnyService::Util.deserialize(response)
    end

    private

    def log(message, severity=Logger::INFO)
      logger.add(severity) {
        "[client #{self.object_id}] #{message}"
      }
    end
  end
end
