require 'bundler/setup'
Bundler.setup(:default, ENV.fetch("RACK_ENV", "development"))

require "lotus/router"
require "coach"

class Index < Coach::Middleware
  def call
    [200, {}, ["hello world!"]]
  end
end

Server = Lotus::Router.new do
  get '/', to: Coach::Handler.new(Index)
end
