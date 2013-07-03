require 'oj'

module Twitocracy
  
  class Updater

    def initialize(address, port, config, status, logger)
      
      # Configure Twitter client
      Twitter.configure do |config|
        config.consumer_key       = ENV['CONSUMER_KEY']
        config.consumer_secret    = ENV['CONSUMER_SECRET']
      end
      
      # fetch them every 60 seconds
      @period = 60
    end

    def run
      clock!
      update!
    end
    
    def clock!
      @timer = EM::PeriodicTimer.new(@period) do
        update!
      end
    end
    
    def restart_clock!
      @timer.cancel 
      EM.add_timer(error.rate_limit.reset_in) { clock! }
    end
  
    def update!
      Fiber.new{
        
        # iterate open proposals    
        Proposal.open.each{ |proposal|
          
          begin
            
            # fill updates hash with retweet counts
            updates = {
            up_retweet_count: retweet_count(proposal,"up"),
            down_retweet_count: retweet_count(proposal,"down")            
            }
            
            # update proposal if there is any update
            proposal.update(updates) unless updates.values.compact.empty?
            
          rescue Twitter::Error::TooManyRequests, Twitter::Error::Unauthorized, Twitter::Error::NotFound, Exception => error
            case error
              
            # try with app token if the owner's token invalidated
            when Twitter::Error::Unauthorized
              # Clear user auth data if unauthorized by twitter and use App token instead
              proposal.user.update_attributes(token: nil, secret: nil, suid: nil)
              retry
              
            # restart clock the updater if rate limit hitted
            when Twitter::Error::TooManyRequests
              # NOTE: Your process could go to sleep for up to 15 minutes but if you
              # retry any sooner, it will almost certainly fail with the same exception.
              restart_clock!
            
            # delete proposal if up or down tweet is removed from master account's timeline  
            # and restart the clock
            when Twitter::Error::NotFound
              proposal.destroy
              restart_clock!
              
            
            # log any other error  
            # TODO: email sysadmin about error or tweet it!
            else 
              ap error.inspect  
            end

          end
        }
        
      }.resume
    end
    
    # get retweets for up or down tweet
    # return nil on any error or counts are same
    def retweet_count proposal, dir
      return nil unless tweet_id = proposal.send(:"#{dir}_tweetid") 
      return nil unless retweet_count = twitter(proposal).status(tweet_id).try(:retweet_count)
      retweet_count if retweet_count != proposal.send(:"#{dir}_retweet_count")      
    end
    
    # use owner's token for fair rate limiting
    def twitter proposal
      twitter = proposal.user.token.present? ? client(proposal.user) : Twitter
    end
    
    def client(user)
      Twitter::Client.new(
      consumer_key: ENV['CONSUMER_KEY'],
      consumer_secret: ENV['CONSUMER_SECRET'],
      oauth_token: user.token,
      oauth_token_secret: user.secret
      )
    end

  end

end