require 'lib/twitocracy/twitter_user'
module Twitocracy
  
  def self.master
    @master ||= Master.new
  end
  
  class Master
    
    include TwitterUser
    
    def id;         0                         end
    def suid;       "MASTER"                  end
    def screenname; "TwitocracyApp"           end
    def token;      ENV['OAUTH_TOKEN']        end
    def secret;     ENV['OAUTH_TOKEN_SECRET'] end

  end
  
end