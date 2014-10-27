module BunnyService
  class Request
    attr_reader :params, :rabbitmq_delivery_info, :rabbitmq_properties

    def initialize(params:, rabbitmq_delivery_info:, rabbitmq_properties:)
      @params = params
      @rabbitmq_delivery_info = rabbitmq_delivery_info
      @rabbitmq_properties = rabbitmq_properties
    end

    def headers
      rabbitmq_properties.headers
    end

    def request_id
      rabbitmq_properties.correlation_id
    end

    def reply_to_queue
      rabbitmq_properties.reply_to
    end
  end
end
