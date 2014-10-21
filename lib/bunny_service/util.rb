module BunnyService
  module Util
    def self.serialize(data)
      JSON.dump(data)
    end

    def self.deserialize(string)
      JSON.load(string)
    end

    def self.generate_uuid
      SecureRandom.uuid
    end
  end
end
