module BunnyService
  class Router
    def initialize(controller:, exchange_name: nil)
      @controller, @exchange_name = controller, exchange_name
    end

    def listen
      @servers = bring_up_servers
      sleep
    rescue Interrupt
      @servers.each(&:teardown)
    end

    def route(service_name:, request:, response:)
      controller.new(request: request, response: response)
        .public_send service_name_to_action(service_name)
    end

    private

    attr_reader :exchange_name, :controller

    def bring_up_servers
      for_each_service_name do |service_name|
        build_server(service_name).listen do |request, response|
          route(request: request, response: response, service_name: service_name)
        end
      end
    end

    def build_server(service_name)
      BunnyService::Server.new(
        exchange_name: exchange_name,
        service_name: service_name,
      )
    end

    def service_name_to_action(service_name)
      action_bindings
        .select { |action, binding_name| binding_name == service_name }
        .keys
        .fetch(0) { raise BindingNotDeclared.new("No binding declared for `#{service_name}` on #{controller.inspect}") }
    end

    def for_each_service_name(&block)
      action_bindings.values.map(&block)
    end

    def action_bindings
      controller.action_bindings
    end

    BindingNotDeclared = Class.new(StandardError)
  end
end
