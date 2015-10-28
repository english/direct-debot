require 'bundler/setup'
Bundler.setup(:default, ENV.fetch('RACK_ENV', 'development'))

require './router'

run Router
