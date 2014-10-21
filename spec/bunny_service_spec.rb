require_relative "../lib/bunny_service.rb"

RSpec.describe "RPC over AMQP" do

  let(:server) {
    BunnyService::Server.new(
      channel: service_channel,
      exchange: service_exchange,
      service_name: service_name,
    )
  }

  let(:client) {
    BunnyService::Client.new(
      channel: client_channel,
      exchange: client_exchange
    )
  }

  let(:bunny) {
    conn = Bunny.new(:automatically_recover => false)
    conn.start
    conn
  }

  let(:exchange_name) { "rpc_test" }

  let(:client_channel) { bunny.create_channel }
  let(:client_exchange) { client_channel.direct(exchange_name) }

  let(:service_channel) { bunny.create_channel }
  let(:service_exchange) { service_channel.direct(exchange_name) }

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
