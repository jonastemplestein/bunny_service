require_relative "../lib/bunny_service.rb"

RSpec.describe "RPC over AMQP" do

  let(:server) {
    BunnyService::Server.new(
      exchange_name: exchange_name,
      service_name: service_name,
    )
  }

  let(:client) {
    BunnyService::Client.new(
      exchange_name: exchange_name,
    )
  }

  let(:exchange_name) { "rpc_test" }
  let(:service_name) { "test.hello_world" }

  let(:params) {
    {
      rpc: "say_hi",
      name: "Bestie",
    }
  }

  let(:response_message) {
    {
      "message" => "Hi Bestie",
    }
  }

  before do
    server.listen do |params|
      name = params.fetch("name")
      { message: "Hi #{name}" }
    end
  end

  it "calls the service and returns the result" do
    response = client.call(service_name, params)
    expect(response).to eq(response_message)
  end

  context "single client calls single service twice sequentially" do
    it "calls the service and returns the result" do
      response = client.call(service_name, params)
      expect(response).to eq(response_message)
      response = client.call(service_name, {name: "peter"})
      expect(response).to eq({"message" => "Hi peter"})
    end
  end
end
