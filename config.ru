require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

require 'airbrake'
require 'newrelic_rpm'
require './lib/gc_me'
require './lib/gc_me/system'

system = GCMe::System.build
system.start

app = GCMe::Application.new(system)

begin
  use Airbrake::Rack::Middleware
  run app.rack_app
ensure
  system.stop
end
