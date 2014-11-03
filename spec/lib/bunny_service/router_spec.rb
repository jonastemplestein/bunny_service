require 'spec_helper'

RSpec.describe BunnyService::Router do
  class TestController
    def self.action_bindings
      { test_action: 'test.foo' }
    end

    def initialize(request:, response:)
      @request, @response = request, response
    end

    def test_action
      { "result" => "test_action got #{@request.params['thing']}" }
    end
  end

  let(:exchange_name) { 'bunny_service_tests' }
  let(:valid_service_name) { 'test.foo' }

  subject(:router) {
    described_class.new(
      exchange_name: exchange_name,
      controller:    TestController,
    )
  }

  describe ".listen" do
    let(:client) {
      BunnyService::Client.new(
        rabbit_url: ENV["RABBIT_URL"],
        exchange_name: exchange_name,
      )
    }

    it "starts a server for each action binding on the given exchange" do
      Timeout::timeout(5) do
        pid = fork { router.listen }
        at_exit { Process.kill(9, pid) }
        response = client.call(valid_service_name, thing: 'baz')
        expect(response.body).to eq({ "result" => "test_action got baz" })
      end
    end
  end

  describe "#route" do
    let(:request)      { double(:request, params: {}) }
    let(:response)     { double(:response) }
    let(:service_name) { valid_service_name }

    it "initializes the controller with the request and response" do
      expect(TestController).to(
        receive(:new)
          .with(request: request, response: response)
          .and_call_original
      )

      router.route(
        service_name: valid_service_name,
        request:      request,
        response:     response,
      )
    end

    context "the controller doesn't have a binding for the service name" do
      it "raises an error" do
        expect {
          router.route(
            service_name: 'bogus.service.name',
            request:      request,
            response:     response,
          )
        }.to raise_error(BunnyService::Router::BindingNotDeclared)
      end
    end
  end
end
