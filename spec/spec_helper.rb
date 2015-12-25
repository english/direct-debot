# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup(:default, :test)

require 'dotenv'
Dotenv.load('.env.test')

require 'sequel'
require 'pry'
require_relative '../config/prius'

Sequel.extension(:migration)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  db = Sequel.connect(Prius.get(:database_url))

  config.before(:suite) do
    Sequel::Migrator.run(db, 'lib/gc_me/db/migrations')
    db[:redirect_flows].truncate
    db[:users].truncate
  end

  config.before(:each) do
    @db = db
  end

  config.around(:each) do |example|
    db.transaction do
      example.call
      fail Sequel::Rollback
    end
  end

  # aggregate failures in all specs
  config.define_derived_metadata { |meta| meta[:aggregate_failures] = true }
end
