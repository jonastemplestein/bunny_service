describe BunnyService::Server do

  let(:exchange_name) { "bunny_service_tests" }
  let(:client) { BunnyService::Client.new(exchange_name: exchange_name) }

  describe "concurrency" do

    it "can run two servers from one thread" do

      s1 = BunnyService::Server.new(
        exchange_name: exchange_name,
        service_name: "test.concurrency.service1",
      ).listen do
        "big success"
      end

      s2 = BunnyService::Server.new(
        exchange_name: exchange_name,
        service_name: "test.concurrency.service2",
      ).listen do
        "big success"
      end

      expect(client.call("test.concurrency.service1").body).
        to eq("big success")
      expect(client.call("test.concurrency.service2").body).
        to eq("big success")

      s1.teardown
      s2.teardown

    end

    it "can run two servers in one thread that concurrently process requests" do

      counter = block_until_thread_count(2)

      s1 = BunnyService::Server.new(
        exchange_name: exchange_name,
        service_name: "test.concurrency.service3",
      ).listen(&counter)

      s2 = BunnyService::Server.new(
        exchange_name: exchange_name,
        service_name: "test.concurrency.service4",
      ).listen(&counter)

      Timeout::timeout(4) do
        child = Thread.fork do
          client = BunnyService::Client.new(exchange_name: exchange_name)
          client.call("test.concurrency.service3")
        end

        client = BunnyService::Client.new(exchange_name: exchange_name)
        expect(client.call("test.concurrency.service4").body).
          to eq("success")

        at_exit do
          Thread.kill(child)
          s1.teardown
          s2.teardown
        end
      end
    end

    it "can concurrently process requests" do

      s = BunnyService::Server.new(
        exchange_name: exchange_name,
        service_name: "test.concurrency.parallel",
      ).listen &block_until_thread_count(2)

      Timeout::timeout(5) do

        child = Thread.fork do
          client = BunnyService::Client.new(exchange_name: exchange_name)
          client.call("test.concurrency.parallel")
        end

        client = BunnyService::Client.new(exchange_name: exchange_name)
        expect(client.call("test.concurrency.parallel").body).
          to eq("success")

        at_exit do
          Thread.kill(child)
          s.teardown # TODO this won't run on exception
        end
      end
    end
  end

  describe "error handling" do
    context "when the server throws an exception" do

      before do
        BunnyService::Server.new(
          service_name: "test.exception1",
          exchange_name: exchange_name,
        ).listen do |request, response|
          raise "pow"
        end
      end

      it "returns the exception" do
        Timeout::timeout(5) do
          expect(client.call("test.exception1").body).to eq({
            "error_message" => "pow"
          })
        end
      end
    end
  end
end
