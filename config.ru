ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

require_relative 'config/prius'

require './router'

run Router
