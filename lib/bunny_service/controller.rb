module BunnyService
  class Controller
    @action_bindings = {}

    def self.listen(exchange_name:)
      servers = @action_bindings.to_h.map do |action_name, service_name|
        BunnyService::Server.new(
          exchange_name: exchange_name,
          service_name: service_name,
        ).listen do |request, response|
          new(request: request, response: response)
            .public_send(action_name)
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

    private

    private_class_method def self.action_bindings(bindings)
      @action_bindings = bindings
    end

    attr_reader :request, :response

  end
end
