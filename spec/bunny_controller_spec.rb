require 'spec_helper'

RSpec.describe BunnyService::Controller do

  class TestController < BunnyService::Controller
    action_bindings(
      foo: 'test.foo',
      bar: 'test.bar',
    )

    def foo
      { result: "foo got #{params.fetch('thing')}" }
    end

    def bar
      { result: "bar got #{params.fetch('thing')}" }
    end
  end

  let(:exchange_name) { 'bunny_service_tests' }
  let(:client)        {
    BunnyService::Client.new(
      rabbit_url: ENV["RABBIT_URL"],
      exchange_name: exchange_name,
    )
  }

  describe ".listen" do
    it "starts a server for each action binding on the given exchange" do
      Timeout::timeout(5) do
        pid = fork { TestController.listen(exchange_name: exchange_name) }
        at_exit { Process.kill(9, pid) }

        expect(client.call('test.foo', thing: 'baz').body).
          to eq "result" => "foo got baz"
        expect(client.call('test.bar', thing: 'qux').body).
          to eq "result" => "bar got qux"
      end
    end
  end

  describe "#handle" do
    let(:controller) {
      TestController.new(
        request: BunnyService::Request.new(
          params: {
            "thing" => "some thing",
          },
          rabbitmq_delivery_info: {},
          rabbitmq_properties: {},
        ),
        response: nil,
      )
    }

    it "translates the action name into a message call via the action bindings" do
      expect(controller.handle(rpc: "test.foo"))
        .to eq(result: "foo got some thing")
    end

    context "when the action is not defined" do
      it "raises an error" do
        expect {
          controller.handle(rpc: "action.does_not_exist")
        }.to raise_error(BunnyService::Controller::ActionNotDefined)
      end
    end
  end
end
