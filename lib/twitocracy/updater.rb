require 'oj'

module Twitocracy
  class Updater

    def initialize(address, port, config, status, logger)
      Twitter.configure do |config|
        config.consumer_key       = ENV['CONSUMER_KEY']
        config.consumer_secret    = ENV['CONSUMER_SECRET']
      end
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
            
        Proposal.open.each{ |proposal|
          begin
            twitter = proposal.user.token.present? ? client(proposal.user) : Twitter
            updates = {}
            begin
              up_retweet_count = proposal.up_tweetid ? twitter.status(proposal.up_tweetid).try(:retweet_count) || 0 : 0
            rescue Twitter::Error::NotFound
              updates[:up_tweetid] = nil
              updates[:up_retweet_count] = 0
            end
            begin
            down_retweet_count = proposal.down_tweetid ? twitter.status(proposal.down_tweetid).try(:retweet_count) || 0 : 0          
            rescue Twitter::Error::NotFound
              updates[:down_tweetid] = nil
              updates[:down_retweet_count] = 0
            end            
            updates[:up_retweet_count] = up_retweet_count if proposal.up_retweet_count != up_retweet_count
            updates[:down_retweet_count] = down_retweet_count if proposal.down_retweet_count != down_retweet_count
            proposal.update(updates) unless updates.values.empty?
          rescue Twitter::Error::TooManyRequests, Twitter::Error::Unauthorized, Exception => error
            case error
            when Twitter::Error::Unauthorized
              # Clear user auth data if unauthorized by twitter and use App token instead
              proposal.user.update_attributes(token: nil, secret: nil, suid: nil)
              retry
            when Twitter::Error::TooManyRequests
              # NOTE: Your process could go to sleep for up to 15 minutes but if you
              # retry any sooner, it will almost certainly fail with the same exception.
              @timer.cancel 
              EM.add_timer(error.rate_limit.reset_in) { clock! }
              # retry
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