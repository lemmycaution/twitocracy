require 'goliath/rack/templates'
require 'lib/twitocracy/router'
require 'lib/twitocracy/session'
require "lib/twitocracy/updater"
require "lib/twitocracy/helpers"
require "app/front"
require "app/back"
require 'bcrypt'

class API < Goliath::API
  
  # to rendering erb templates
  include Goliath::Rack::Templates
  
  # easy routing for goliath
  include Twitocracy::Router 
  
  # easy routing for goliath
  include Twitocracy::Helpers   
  
  use Rack::Static,                     
  :root => Goliath::Application.root_path("public"),
  :urls => ["/favicon.ico", '/styles', '/scripts', '/images'],
  :cache_control => 'public, max-age=3600'
  use Goliath::Rack::Render
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Params  
  
  # bloody sessions
  use Goliath::Rack::SimpleAroundwareFactory, Twitocracy::Session
  
  # periodic worker to update reweet(vote) counts
  plugin Twitocracy::Updater
  
  # FRONT-END API
  include Front  

  # BACK-END API
  include Back
  
  # HELPERS

  def authenticate_user!
    error 422 unless current_user
  end

  def current_user
    User.online.find_by(suid: session["suid"])
  end

  def generate_sid(salt = Time.now)
    ::BCrypt::Password.create(salt)    
  end

  def session
    env[Twitocracy::Session::ENV_SESSION_KEY] || {}
  end
  
end
