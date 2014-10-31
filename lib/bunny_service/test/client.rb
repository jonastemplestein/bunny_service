module BunnyService
  module Test
    class Client
      def initialize
        reset!
      end

      attr_reader :calls

      # TODO allow stub for specific params
      def stub(service_name, &block)
        stubs[service_name] = block
      end

      def call(service_name, params={}, headers={})
        calls.push(
          service_name: service_name,
          params: params,
          headers: headers
        )
        if stubs[service_name]
          stubs[service_name].call
        end
      end

      def reset!
        @calls, @stubs  = [], {}
      end

      private

      attr_reader :stubs
    end
  end
end
