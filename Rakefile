# rubocop:disable Lint/HandleExceptions
begin
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:test)
  RuboCop::RakeTask.new

  task default: ['rubocop:auto_correct', :test]
rescue LoadError
end
# rubocop:enable Lint/HandleExceptions

task deploy: [:rubocop, :test] do
  sh 'git push heroku master'

  # block until app has spun up
  sh 'curl https://direct-debot-sandbox.herokuapp.com/'
end
