require 'spec_helper'

class TestController < BunnyService::Controller
  action_bindings(
    foo: 'test.foo',
    bar: 'test.bar',
  )

  def foo
    { result: "foo got #{params['thing']}" }
  end

  def bar
    { result: "bar got #{params['thing']}" }
  end
end

RSpec.describe BunnyService::Controller do
  let(:exchange_name) { 'bunny_service_tests' }
  let(:client)        { BunnyService::Client.new(exchange_name: exchange_name) }

  describe ".listen" do
    it "handles messages for the action bindings on the given exchange" do
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
end
