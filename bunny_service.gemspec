$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bunny_service/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bunny_service"
  s.version     = BunnyService::VERSION
  s.authors     = ["Jonas Huckestein", "Mike Kelly", "Stephen Best", "Tom Blomfield"]
  s.email       = ["jonas@bankpossible.com"]
  s.homepage    = "https://github.com/jonashuckestein/bunny-service"
  s.summary     = "RPC service/client implementation for rabbit mq"
  s.description = "see summary?"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "bunny"
  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
end
