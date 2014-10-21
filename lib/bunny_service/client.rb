require "bunny"
require "thread"
require "json"

module BunnyService
  class Client
    attr_reader :reply_queue
    attr_accessor :response, :call_id
    attr_reader :lock, :condition

    def initialize(channel:, exchange:)
      @channel = channel
      @exchange = exchange

      @reply_queue    = @channel.queue("", exclusive: true)

      @lock      = Mutex.new
      @condition = ConditionVariable.new
      that       = self

      puts "[client] initializing client"

      @reply_queue.subscribe do |delivery_info, properties, payload|
        puts "[client] received service response: #{payload.inspect}"
        if properties[:correlation_id] == that.call_id
          that.response = payload
          that.lock.synchronize{that.condition.signal}
        end
      end
      puts "[client] subscribed to callback queue #{@reply_queue.name}"
    end

    def call(service_name, payload={})
      self.call_id = self.generate_uuid

      puts "[client] calling '#{service_name}' service w/ #{payload.inspect}"

      raise "Payload has to be a Hash" unless payload.is_a?(Hash)

      @exchange.publish(serialize(payload),
        routing_key: service_name,
        correlation_id: call_id,
        reply_to: @reply_queue.name)

      lock.synchronize{condition.wait(lock)}
      puts "[client] got response '#{response}'"
      deserialize(response)
    end

    def serialize(data)
      JSON.dump(data)
    end

    def deserialize(string)
      JSON.load(string)
    end

    protected

    def generate_uuid
      # very naive but good enough for code
      # examples
      "#{rand}#{rand}#{rand}"
    end
  end
end
