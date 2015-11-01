ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

require 'prius'
require './config/prius'
require './application'

db = Sequel.connect(Prius.get(:database_url))
run Application.build(db)
