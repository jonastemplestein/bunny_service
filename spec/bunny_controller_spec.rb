require 'spec_helper'

class TestController < BunnyService::Controller
  action_bindings(
    foo: 'example.foo',
    bar: 'example.bar',
  )

  def foo
    { result: "foo got #{params['thing']}" }
  end

  def bar
    { result: "bar got #{params['thing']}" }
  end
end

RSpec.describe BunnyService::Controller do
  let(:exchange_name) { 'bunny_service_test_exchange' }
  let(:client)        { BunnyService::Client.new(exchange_name: exchange_name) }

  describe ".listen" do
    it "handles messages for the action bindings on the given exchange" do
      Timeout::timeout(5) do
        pid = fork { TestController.listen(exchange_name: exchange_name) }
        at_exit { Process.kill(9, pid) }

        expect(client.call('example.foo', thing: 'baz')).to eq "result" => "foo got baz"
        expect(client.call('example.bar', thing: 'qux')).to eq "result" => "bar got qux"
      end
    end
  end
end
