module Twitocracy
  module TwitterUser

    extend ActiveSupport::Concern
    
    def status_get(tweet)
      client.status(tweet)
    end
    
    def status_update(tweet)
      client.update(tweet)
    end
    
    def status_retweet(tweetid)
      client.retweet(tweetid)
    end
    
    def status_destroy(tweetid)
      client.status_destroy(tweetid)            
    end
    
    private
    
    def client
      Twitter::Client.new(
      :consumer_key => ENV['CONSUMER_KEY'],
      :consumer_secret => ENV['CONSUMER_SECRET'],
      :oauth_token => self.token,
      :oauth_token_secret => self.secret
      )
    end

  end
end