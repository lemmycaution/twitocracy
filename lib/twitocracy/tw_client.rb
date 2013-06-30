module Twitocracy
  class TwClient
    def self.tweet(user,tweet)
      self.client(user).update(tweet)
    end
    def self.retweet(user,tweetid)
      self.client(user).retweet(tweetid)
    end
    def self.destroy(user,tweetid)
      self.client(user).status_destroy(tweetid)            
    end
    def self.client(user)
      Twitter::Client.new(
        :consumer_key => ENV['CONSUMER_KEY'],
        :consumer_secret => ENV['CONSUMER_SECRET'],
        :oauth_token => user.token,
        :oauth_token_secret => user.secret
      )
    end
  end
end