require "bunny"
require "thread"
require "json"

module BunnyService
  class Client

    attr_reader :options

    # Used to pass data between main thread and networking thread
    attr_accessor :response, :request_id

    def initialize(options={})
      @options = {
        rabbit_url: ENV["RABBIT_URL"],
        exchange_name: "amq.direct",
        logger: Logger.new(STDOUT),
      }.merge(options)

      log "Initializing client"

      # Each client creates one exclusive queue for responses. At each time,
      # just one call can be in-flight per client.
      reply_queue.subscribe do |delivery_info, properties, payload|
        # This code is executed in the networking thread. If this is a
        # reponse to the currently in-flight request, we store the result and
        # signal the main thread.
        if properties.correlation_id == request_id
          self.response = payload
          lock.synchronize { condition.signal }
        else
          # TODO once we implement timeouts, this might happen frequently
          raise "Received errand correlation id #{properties.correlation_id}" +
            "on queue #{reply_queue.name} (expecting #{request_id})"
        end
      end

      log "Subscribed to exclusive queue #{reply_queue.name}"
    end

    # Publishes a service request on the exchange. For example:
    # service_client.call("lazy.sleep", {duration: 5})
    def call(service_name, payload={})
      raise "Payload has to be a Hash" unless payload.is_a?(Hash)

      self.request_id = BunnyService::Util.generate_uuid
      payload = BunnyService::Util.serialize(payload)
      log "[#{request_id}] Calling #{service_name} w/ #{payload})"

      exchange.publish(
        payload,
        persistent: false,
        mandatory: false,
        routing_key: service_name,
        correlation_id: request_id,
        reply_to: reply_queue.name)

      # The response will be asynchronously received in bunny's networking
      # thread. In the main thread we wait for the networking thread to
      # signal that the response was received
      # TODO what about a timeout?
      lock.synchronize { condition.wait(lock) }

      log "[#{request_id}] Got response: #{response}"
      deserialized_response = BunnyService::Util.deserialize(response)

      self.request_id = nil
      self.response = nil

      deserialized_response
    end

    def reply_queue
      # TODO for some reason this exclusive queue always needs to be bound
      # to the default exchange. Why?
      @reply_queue ||= channel.temporary_queue
    end

    def connection
      @connection ||= Bunny.new(options.fetch(:rabbit_url)).start
    end

    def channel
      @channel ||= connection.create_channel
    end

    def exchange
      @exchange ||= channel.direct(
        options.fetch(:exchange_name),
        durable: false,
      )
    end

    def lock
      @lock ||= Mutex.new
    end

    def condition
      @condition ||= ConditionVariable.new
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
