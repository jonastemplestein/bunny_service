require "bunny_service"
require "pry"


server = BunnyService::Server.new(
  exchange_name: "rpc_test",
  service_name: "console.test",
)

client = BunnyService::Client.new(
  exchange_name: "rpc_test",
)

def start_sleep_server(service_name)
  BunnyService::Server.new(
    exchange_name: "",
    service_name: service_name,
  ).listen do |payload|
    sleep(payload["duration"].to_f)
    {message: "Slept for #{payload["duration"]}"}
  end
end

def start_sleep_clients
  child_pid = fork do
    c1 = BunnyService::Client.new(
      exchange_name: "rpc_test",
    )
    while true
      c1.call("s1", {duration: "10"})
    end
  end
  c2 = BunnyService::Client.new(
    exchange_name: "rpc_test",
  )
  while true
    c2.call("s1", {duration: "10"})
  end
end

binding.pry
