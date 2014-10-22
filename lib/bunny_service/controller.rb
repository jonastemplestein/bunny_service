module BunnyService
  class Controller
    @action_bindings = {}

    def self.listen(exchange_name:)
      servers = @action_bindings.to_h.map do |action_name, service_name|
        BunnyService::Server.new(
          exchange_name: exchange_name,
          service_name: service_name,
        ).listen do |params, response, request|
          new(params: params, response: response, request: request)
            .public_send(action_name)
        end
      end
      sleep
    rescue Interrupt
      servers.each(&:teardown)
    end

    def initialize(params:, response:, request:)
      @params, @response, @request = params, response, request
    end

    private

    private_class_method def self.action_bindings(bindings)
      @action_bindings = bindings
    end

    attr_reader :params, :response, :request
  end
end
