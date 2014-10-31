require 'rspec/expectations'

RSpec::Matchers.define :have_handled do |expected|
  match do |service|
    expect(service.calls).to include hash_including(expected)
  end
end

module BunnyService
  module Test
    module Helpers
      def service_client
        @service_client ||= BunnyService::Test::Client.new
      end

      def stub_service_client
        allow(BunnyService::Client).to receive(:new).and_return(service_client)
      end

      def stub_service(key, &block)
        service_client.stub(key, &block)
      end

      def success_response(body = {})
        bunny_response(body, success: true)
      end

      def error_response(body = {})
        bunny_response(body, success: false)
      end

      def bunny_response(body, success: true)
        double(
          :response,
          body: body,
          headers: {},
          status: success ? 200 : 400,
          success?: success,
        )
      end
    end
  end
end
