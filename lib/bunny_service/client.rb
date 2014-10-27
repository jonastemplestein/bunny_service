require "bunny"
require "thread"
require "json"

module BunnyService
  class Client

    attr_reader :rabbit_url, :exchange_name, :logger

    # Used to pass data between main thread and networking thread
    attr_accessor :response, :request_id

    def initialize(options={})
      @rabbit_url = options.fetch(:rabbit_url)
      @exchange_name = options.fetch(:exchange_name)
      @logger = options[:logger] || Logger.new(STDERR)
    end

    def subscribe_to_reply_queue
      # TODO test that multiple #call calls don't create multiple subscriptions
      # Each client creates one exclusive queue for responses. At each time,
      # just one call can be in-flight per client.
      @reply_subscription ||= reply_queue.subscribe do |delivery_info, properties, payload|
        # This code is executed in the networking thread. If this is a
        # reponse to the currently in-flight request, we store the result and
        # signal the main thread.
        if properties.correlation_id == request_id
          self.response = Response.new(
            body: BunnyService::Util.deserialize(payload),
            headers: properties.headers,
          )
          lock.synchronize { condition.signal }
        else
          # TODO once we implement timeouts, this might happen frequently
          raise "Received errand correlation id #{properties.correlation_id}" +
            "on queue #{reply_queue.name} (expecting #{request_id})"
        end
      end
      log "Subscribed to exclusive queue #{reply_queue.name}"
      nil
    end

    # Publishes a service request on the exchange. For example:
    # service_client.call("lazy.sleep", {duration: 5})
    def call(service_name, params={}, headers={})

      subscribe_to_reply_queue

      raise "Payload has to be a Hash" unless params.is_a?(Hash)

      self.request_id = BunnyService::Util.generate_uuid
      payload = BunnyService::Util.serialize(params)
      log "[#{request_id}] Calling #{service_name} w/ #{payload})"

      exchange.publish(
        payload,
        persistent: false,
        mandatory: false,
        headers: headers,
        routing_key: service_name,
        correlation_id: request_id,
        reply_to: reply_queue.name)

      # The response will be asynchronously received in bunny's networking
      # thread. In the main thread we wait for the networking thread to
      # signal that the response was received
      # TODO what about a timeout?
      lock.synchronize { condition.wait(lock) }

      log "[#{request_id}] Got response: #{response.body.inspect}"

      response.tap {
        self.response = nil
        self.request_id = nil
      }
    end

    def reply_queue
      # TODO for some reason this exclusive queue always needs to be bound
      # to the default exchange. Why?
      @reply_queue ||= channel.temporary_queue
    end

    def connection
      @connection ||= Bunny.new(rabbit_url).start
    end

    def channel
      @channel ||= connection.create_channel
    end

    def exchange
      @exchange ||= channel.direct(
        exchange_name,
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
      logger.add(severity) {
        "[client #{self.object_id}] #{message}"
      }
    end
  end
end
