module BunnyService
  class Controller
    def self.action_bindings(bindings = nil)
      @action_bindings ||= bindings
    end

    def initialize(request:, response:)
      @request, @response = request, response
    end

    private

    def params
      request.params
    end

    def respond_with(*args)
      response.respond_with(*args)
    end

    attr_reader :request, :response
  end
end
