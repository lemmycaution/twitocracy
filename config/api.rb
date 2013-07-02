require 'uri'
require 'em-synchrony/activerecord'
require 'yaml'
require 'erb'
require 'faraday'

# Sets up database configuration
db = URI.parse(ENV['DATABASE_URL'] || 'http://localhost')
if db.scheme == 'postgres' # Heroku environment
  ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'em_postgresql' : db.scheme,
  :host     => db.host,
  :username => db.user,
  :port     => db.port,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8',
  :pool     => 6,
  :connections => 6
  )
else # local environment
  environment = ENV['DATABASE_URL'] ? 'production' : 'development'
  db = YAML.load(ERB.new(File.read('config/database.yml')).result)[environment]
  ActiveRecord::Base.establish_connection(db)
end

# if ENV['RACK_ENV']=="development" # && !const_defined?("OpenSSL::SSL::VERIFY_PEER")
#   OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 
# end

if ENV['RACK_ENV']=="development"
  config[:dalli] = Dalli::Client.new('localhost:11211', { 
    :namespace => "twote", :compress => true, :threadsafe => true })
else
  config[:dalli] = Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
                      {:username => ENV["MEMCACHIER_USERNAME"],
                       :password => ENV["MEMCACHIER_PASSWORD"],
                       :namespace => "twote", 
                       :compress => true, 
                       :threadsafe => true})
end

config["twitter_oauth"] = TwitterOAuth::Client.new(
  :consumer_key => ENV['CONSUMER_KEY'],
  :consumer_secret => ENV['CONSUMER_SECRET']
)

config[:template] = {
  layout_engine:     :erb,
  layout:            "layout",
  views:             Goliath::Application.root_path('app/views'),
}

# Faraday.default_connection = Faraday::Connection.new do |builder|
#   builder.use Faraday::Adapter::EMSynchrony 
# end

# Twitter.middleware = Faraday::Builder.new(
#   &Proc.new do |builder|
#     # Specify a middleware stack here
#     builder.use Faraday::Adapter::EMSynchrony 
#   end
# )

Pusher.url = "http://#{ENV['PUSHER_KEY']}:#{ENV['PUSHER_SECRET']}@api.pusherapp.com/apps/#{ENV['PUSHER_APP']}"

require "app/models/user"
require "app/models/proposal"
require "app/models/retweet"