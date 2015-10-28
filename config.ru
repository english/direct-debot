require 'bundler/setup'
Bundler.setup(:default, ENV.fetch('RACK_ENV', 'development'))

require 'dotenv'
Dotenv.load

require_relative 'config/prius'

require './router'

run Router
