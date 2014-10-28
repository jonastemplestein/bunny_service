module BunnyService
  class Controller
    @action_bindings = {}

    def self.listen(exchange_name:)
      servers = action_bindings.values.map do |service_name|
        BunnyService::Server.new(
          exchange_name: exchange_name,
          service_name: service_name,
        ).listen do |request, response|
          new(request: request, response: response)
            .handle(rpc: service_name)
        end
      end
      sleep
    rescue Interrupt
      servers.each(&:teardown)
    end

    def initialize(request:, response:)
      @request, @response = request, response
    end

    def params
      request.params
    end

    def respond_with(*args)
      response.respond_with(*args)
    end

    def handle(rpc:)
      public_send(action_to_method(rpc))
    end

    private

    def action_to_method(search_action)
      action_bindings
        .select { |method_id, action|
          search_action == action
        }
        .keys
        .fetch(0) {
          raise ActionNotDefined.new("Action `#{search_action}` not defined on #{self.inspect}")
        }
    end

    def action_bindings
      self.class.send(:action_bindings)
    end

    private_class_method def self.action_bindings(bindings = nil)
      @action_bindings ||= bindings
    end

    attr_reader :request, :response

    ActionNotDefined = Class.new(StandardError)
  end
end
