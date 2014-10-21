require "bunny_service"

require_relative "helpers/concurrency_helper"

RSpec.configure do |config|
  config.include BunnyService::ConcurrencyHelper

  config.before(:each) do
    # TODO clean up rabbitmq structures
  end

  config.before(:each) do
    # TODO clean up rabbitmq structures
  end
end
