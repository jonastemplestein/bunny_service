RSpec.describe BunnyService::Client do

  let(:server) {
    BunnyService::Server.new(
      rabbit_url: ENV.fetch("RABBIT_URL"),
      exchange_name: exchange_name,
      service_name: service_name,
    )
  }

  let(:client) {
    BunnyService::Client.new(
      rabbit_url: ENV.fetch("RABBIT_URL"),
      exchange_name: exchange_name,
    )
  }

  let(:exchange_name) { "bunny_service_tests" }
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


  describe "#call" do

    before do
      server.listen do |request, response|
        name = request.params.fetch("name")
        { message: "Hi #{name}" }
      end
    end
    after do
      server.teardown
    end

    it "calls the service and returns the result" do
      response = client.call(service_name, params)
      expect(response.body).to eq(response_message)
    end

    context "single client calls single service twice sequentially" do
      it "calls the service and returns the result" do
        response = client.call(service_name, params)
        expect(response.body).to eq(response_message)
        response = client.call(service_name, {name: "peter"})
        expect(response.body).to eq({"message" => "Hi peter"})
      end
    end

    context "calling a service that doesn't exist (timeout)" do
      it "returns a timeout error" do
        response = client.call("service_that_doesnt_exist", {}, timeout: 0.5)
        expect(response.body).to match(error_message: /timed out/)
        expect(response.status).to eq(504)
      end
    end
  end

end
