source 'https://rubygems.org'

ruby '2.3.0'

gem 'puma', '~> 2.14'
gem 'lotus-router', '~> 0.4'
gem 'coach', '~> 0.4.0'
gem 'prius', '~> 1.0'
gem 'oauth2', '~> 1.0'
gem 'gocardless_pro', '~> 1.0'
gem 'rack', '~> 1.6.4'
gem 'json_schema', '~> 0.7'
gem 'sequel', '~> 4.27'
gem 'mail', '~> 2.6.3'
gem 'hamster', github: 'hamstergem/hamster'
gem 'rake', '~> 10.4.2'

group :production do
  gem 'pg', '~> 0.18'
end

group :development, :test do
  gem 'rspec', '~> 3.3'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'dotenv', '~> 2.0'
  gem 'sqlite3', '~> 1.3'
end

group :development do
  gem 'rubocop', github: 'bbatsov/rubocop'
end

group :test do
  gem 'webmock', '~> 1.22'
  gem 'rantly', '~> 0.3.2'
end
