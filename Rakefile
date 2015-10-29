begin
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:test)
  RuboCop::RakeTask.new

  task default: ['rubocop:auto_correct', :test]
rescue LoadError
end
