# An instance of BunnyService::Response is returned from service calls:
# response = BunnyService::Client.new(...).call("some_service", {...})
module BunnyService
  class Response

    attr_reader :body, :headers

    def initialize(body: nil, headers: {})
      @body = body
      @headers = headers
      headers["status"] = 200 if status.nil?
    end

    def success?
      status >= 200 && status < 300
    end

    def error?
      !success?
    end

    def error_message
      success? ? nil : body["error_message"]
    end

    def status
      headers["status"]
    end
  end
end

