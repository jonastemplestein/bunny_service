require "bunny_service"
require "pry"

connection = Bunny.new(automatically_recover: false)
connection.start

server = BunnyService::Server.new(
  connection: connection,
  exchange_name: "rpc_test",
  service_name: "console.test",
)

client = BunnyService::Client.new(
  connection: connection,
  exchange_name: "rpc_test",
)

def start_sleep_server(service_name, connection)
  BunnyService::Server.new(
    connection: connection,
    exchange_name: "rpc_test",
    service_name: service_name,
  ).listen do |payload|
    sleep(payload["duration"].to_f)
    {message: "Slept for #{payload["duration"]}"}
  end
end

binding.pry
