# fix for "ArgumentError: invalid byte sequence in US-ASCII" during bundle install (?)
Encoding.default_internal = Encoding.default_external = Encoding::UTF_8

source "http://rubygems.org"

# TODO: update to 5.x
gem 'twitter', '~> 4.4'
gem 'oauth'
gem 'multi_json'

group :development do
  gem 'capistrano'
  gem 'rvm-capistrano'
  gem 'sinatra'
  gem 'sinatra-reloader'
end
