module BunnyService

  class ResponseWriter < Response

    attr_writer :body, :headers

    def status=(status)
      headers["status"] = status
    end

    def respond_with_exception(e, status=500)
      self.body = {
        "error_message" => e.message
      }
    end

    def respond_with(body, options={})

      if body.is_a?(Exception)
        return respond_with_exception(body)
      end

      self.body = body
      if options[:headers].is_a?(Hash)
        headers.merge(options[:headers])
      end

      self.status = options[:status].nil? ? 200 : options[:status]
      self
    end
  end
end

