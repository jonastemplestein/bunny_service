require "bunny_service"

require_relative "helpers/concurrency_helper"

RSpec.configure do |config|
  config.include BunnyService::ConcurrencyHelper
  config.warnings = false

  config.before(:each) do
    # TODO clean up rabbitmq structures
  end

  config.after(:all) do
  end

  config.before(:each) do
    # TODO clean up rabbitmq structures
  end
end
