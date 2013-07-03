require 'lib/twitocracy/client'

module Twitocracy
  
  # Master User for managing master tweets
  # http://twitter.com/TwitocracyApp
  class Master
  
    include Client
  
    def screenname; "TwitocracyApp"           end
    def token;      ENV['OAUTH_TOKEN']        end
    def secret;     ENV['OAUTH_TOKEN_SECRET'] end

  end
  
end