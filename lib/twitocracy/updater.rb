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
  
    def update!
      Fiber.new{
        
        # iterate open proposals    
        Proposal.open.each{ |proposal|
          begin
            
            # use owner's token for fair rate limiting
            twitter = proposal.user.token.present? ? client(proposal.user) : Twitter
            
            # hash for possible updates
            updates = {}
            
            # get retweets for uptweet
            up_retweet_count = proposal.up_tweetid ? twitter.status(proposal.up_tweetid).try(:retweet_count) || 0 : 0
            # get retweets for downtweet            
            down_retweet_count = proposal.down_tweetid ? twitter.status(proposal.down_tweetid).try(:retweet_count) || 0 : 0                    
            # fill updates hash if counts are different
            updates[:up_retweet_count] = up_retweet_count if proposal.up_retweet_count != up_retweet_count
            updates[:down_retweet_count] = down_retweet_count if proposal.down_retweet_count != down_retweet_count
            # update proposal!
            proposal.update(updates) unless updates.values.empty?
          rescue Twitter::Error::TooManyRequests, Twitter::Error::Unauthorized, Twitter::Error::NotFound, Exception => error
            case error
              
            # try with app token if the owner's token invalidated
            when Twitter::Error::Unauthorized
              # Clear user auth data if unauthorized by twitter and use App token instead
              proposal.user.update_attributes(token: nil, secret: nil, suid: nil)
              retry
              
            # re-clock the updater if rate limit hitted
            when Twitter::Error::TooManyRequests
              # NOTE: Your process could go to sleep for up to 15 minutes but if you
              # retry any sooner, it will almost certainly fail with the same exception.
              @timer.cancel 
              EM.add_timer(error.rate_limit.reset_in) { clock! }
            
            # delete proposal if up or down tweet is removed from master account's timeline  
            # and restart the clock
            when Twitter::Error::NotFound
              proposal.destroy
              @timer.cancel 
              EM.add_timer(error.rate_limit.reset_in) { clock! }
            
            # log any other error  
            # TODO: email sysadmin about error or tweet it!
            else 
              ap error.inspect  
            end

          end
        }
        
      }.resume
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