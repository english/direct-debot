require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

require 'prius'
require 'sequel'
require './config/prius'
require './lib/gc_me'

db = Sequel.connect(Prius.get(:database_url))
Sequel::Migrator.run(db, 'lib/gc_me/db/migrations')

run GCMe.build(db)
