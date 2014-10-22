describe BunnyService::Server do

  let(:exchange_name) { "bunny_service_tests" }
  let(:client) { BunnyService::Client.new(exchange_name: exchange_name) }

  it "can run two servers in one thread" do

    s1 = BunnyService::Server.new(
      exchange_name: exchange_name,
      service_name: "s1",
    ).listen do
      "big success"
    end

    s2 = BunnyService::Server.new(
      exchange_name: exchange_name,
      service_name: "s2",
    ).listen do
      "big success"
    end

    expect(client.call("s1")).to eq("big success")
    expect(client.call("s2")).to eq("big success")

    s1.teardown
    s2.teardown

  end

  it "can run two servers in one thread that concurrently process requests" do

    counter = block_until_thread_count(2)

    s1 = BunnyService::Server.new(
      exchange_name: exchange_name,
      service_name: "concurrent_1",
    ).listen(&counter)

    s2 = BunnyService::Server.new(
      exchange_name: exchange_name,
      service_name: "concurrent_2",
    ).listen(&counter)

    Timeout::timeout(4) do
      pid = fork do
        #client = BunnyService::Client.new(exchange_name: exchange_name)
        client.call("concurrent_1")
      end

      #client = BunnyService::Client.new(exchange_name: exchange_name)
      expect(client.call("concurrent_2")).to eq("success")

      # TODO tear down s1 and s2
      at_exit do
        Process.kill(9, pid)
      end
    end
  end

  it "can concurrently process requests" do

    s = BunnyService::Server.new(
      exchange_name: exchange_name,
      service_name: "test_service",
    ).listen &block_until_thread_count(2)

    Timeout::timeout(5) do

      pid = fork do
        client = BunnyService::Client.new(exchange_name: exchange_name)
        client.call("test_service")
      end

      client = BunnyService::Client.new(exchange_name: exchange_name)
      client.call("test_service")

      at_exit do
        Process.kill(9, pid)
        s.teardown # TODO this won't run on exception
      end
    end
  end

  # TODO specs for a bunch of other crap
end
