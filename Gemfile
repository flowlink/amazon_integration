source 'https://rubygems.org'

gem 'capistrano', '>= 3.0.0.pre13'
gem 'geokit'
gem 'honeybadger'
gem 'httparty'
gem 'model_un'
gem 'mws-connect' # Mws
gem 'nokogiri'
gem 'peddler' # MWS
gem 'redis'
gem 'require_all'
gem 'sinatra'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'

group :development do
  gem 'shotgun'
end

group :development, :test do
  gem 'dotenv'
  gem 'pry'
  gem 'pry-byebug'
end

group :test do
  gem 'guard-rspec'
  gem 'rack-test'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rspec'
  gem 'terminal-notifier-guard'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end

gem 'endpoint_base', github: 'flowlink/endpoint_base'
