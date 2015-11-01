require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

require 'prius'
require 'sequel'
require './config/prius'
require './lib/gc-me'

db = Sequel.connect(Prius.get(:database_url))
run GCMe.build(db)
