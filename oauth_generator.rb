require 'bundler/setup'
require 'oauth'

config = YAML.load(File.read('config/config.yml'))

oauth = OAuth::Consumer.new(
  config['consumer_key'],
  config['consumer_secret'],
  :site => 'http://twitter.com/',
  :request_token_path => '/oauth/request_token',
  :access_token_path => '/oauth/access_token',
  :authorize_path => '/oauth/authorize'
)

rt = oauth.get_request_token
request_token = rt.token
request_secret = rt.secret

puts "Request token => #{request_token}"
puts "Request secret => #{request_secret}"
puts "Authentication URL => #{rt.authorize_url} [OPEN THIS]"

print "Provide the PIN that Twitter gave you here: "
pin = gets.chomp

at = rt.get_access_token(oauth_verifier: pin)
access_token = at.token
access_secret = at.secret

puts "Access token => #{at.token}"
puts "Access secret => #{at.secret}"
