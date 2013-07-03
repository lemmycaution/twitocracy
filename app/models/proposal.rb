class Proposal < ActiveRecord::Base
  
  # default per page limit for pagination
  DEFAULT_LIMIT = 8
  
  # Twitter API v.1.1 limits /statuses/show/:id resource to 180 per user token for 15 minutes
  # Since Twitocracy fetches tweets of each proposal per minute
  # every user can have max 180 / 15 = 12 proposals actively to keep running in rate limit
  # more info https://dev.twitter.com/docs/rate-limiting/1.1
  MAX_COUNT_PER_USER = 12
  
  # t.co urls need 22 (23 for https) character
  # since Twitocracy puts proposal url in every tweet
  # we need to reserve this length
  SHORT_URL_LENGTH = 23
  TWEET_LENGTH = 140
  PROPOSAL_TWEET_LENGTH = TWEET_LENGTH - SHORT_URL_LENGTH
  
  # every proposal has a creator obviously
  belongs_to :user
  
  # standard validations
  validates_presence_of :user_id, :subject, :up_tweet, :started_at, :finished_at
  validates_presence_of :down_tweet, if: lambda { |proposal| proposal.is_pool }  
  
  # fit in a tweet
  validates_length_of :subject,     maximum: PROPOSAL_TWEET_LENGTH, if: lambda { |proposal| !proposal.is_pool }
  validates_length_of :up_tweet,    maximum: PROPOSAL_TWEET_LENGTH
  validates_length_of :down_tweet,  maximum: PROPOSAL_TWEET_LENGTH, if: lambda { |proposal| proposal.is_pool }  
  
  # up and down tweets must be different
  validate :validate_up_down_tweet_diff, if: lambda { |proposal| proposal.is_pool }    
  
  # validate time of voting
  validate :validate_started_at
  validate :validate_finished_at
  
  # to keep things alive, look MAX_COUNT_PER_USER for more info
  validate :validate_count_against_rate_limit
  
  # when down voting is disabled, proposal form has no field for up tweet 
  # because subject is the only tweet, so copy it from subject field
  before_validation :generate_up_tweet_from_subject, if: lambda { |proposal| !proposal.is_pool }  
  
  # cleaning
  before_destroy    :remove_from_twitter
  
  # tweet up and or down tweets from TwitocracyApp account
  after_create  :create_master_tweets
  
  # push updates to browser via Pusher app
  after_create  lambda { |p| p.push(:create) }
  after_update  lambda { |p| p.push(:update) }
  after_destroy lambda { |p| p.push(:destroy) }
  
  # handy scopes
  scope :latest,    -> { order(created_at: :desc) }
  # TODO: fix pg error
  # scope :critical,  -> { order("ABS(finished_at - now())") }  
  scope :up,        -> { order(up_retweet_count: :desc) }    
  scope :down,      -> { order(down_retweet_count: :desc) }      
  scope :closed,    -> { where("finished_at < ?", Time.now.at_end_of_day) }      
  scope :open,      -> { where("started_at < ? and finished_at > ?", Time.now.at_end_of_day, Time.now.beginning_of_day) }        
  scope :upcoming,  -> { where("started_at > ?", Time.now.at_end_of_day) }          
  scope :page,      lambda {|page| limit(DEFAULT_LIMIT).offset((page-1)*DEFAULT_LIMIT) }  
  default_scope     -> { latest }
  
  # non recordable attributes
  attr_accessor :downvoting_enabled
  attr_accessor :owner_vote  
  
  # Proposal#upvote_by(user) 
  # Proposal#downvote_by(user)
  #
  # up and down voting
  # takes user parameter
  # mostly current signed in user
  %w(up down).each do |dir|
    class_eval <<-CODE 
    
    def #{dir}vote_by(user)
      
        begin
          
          # check if the user has retweeted in other direction before
          if self.is_pool
            if user.status(self.#{dir == "up" ? "down" : "up"}_tweetid).try(:retweeted)
              self.errors.add(:base, "You have already voted on this proposal")  
              return false
            end
          end
          
          # retweet the vote tweet on behalf of user
          # and update the vote counts (retweet counts)
          tweets = user.retweet(self.#{dir}_tweetid)
          unless tweets.empty?
            if total_retweet_count = tweets.map(&:retweet_count).inject(:+)
              self.update(:"#{dir}_retweet_count" => total_retweet_count) 
            end
          else
            self.errors.add(:base, "Sorry, your vote has not been casted")  
            return false
          end
            
        rescue Exception => e
          ap "Proposal##{dir}vote_by \#{e.inspect}"
          self.errors.add(:base, e.message)
          return false
        end
        
    end
    
    CODE
  end
  
  def as_json(options = {})
    options = options.merge(methods: [:owner,:is_pool,:upvote_count,:downvote_count])
    super(options)
  end
  
  # helper for json representation
  def owner
    self.user.screenname
  end
  
  # is proposal downvoting enabled or not
  def is_pool
    self.persisted? ? self.down_tweet.present? : self.downvoting_enabled.present?
  end
  
  # is in voting
  def is_open
    self.started_at < Time.now.at_end_of_day and self.finished_at > Time.now.beginning_of_day
  end
  
  # another helper for json representation
  def upvote_count
    self.up_retweet_count
  end
  
  # yes, it is
  def downvote_count
    self.down_retweet_count
  end
  
  # send object to client
  def push(event)
    Pusher[event == :create ? 'proposals' : "proposal-#{self.id}"].trigger(event, self.as_json)
  end

  # for universal access
  def public_url
    "http://twitocracy.herokuapp.com/#{self.id}"
  end
  
  private

  def generate_up_tweet_from_subject
    self.up_tweet = self.subject
  end
  
  # puts public url into tweet before tweeting, tweets are not saving in db without this modification
  def inject_url_into_tweets
    self.up_tweet   = "#{self.up_tweet} #{public_url}" if !self.up_tweet.include?(public_url)
    self.down_tweet = "#{self.down_tweet} #{public_url}" if self.is_pool && !self.down_tweet.include?(public_url)
  end
  
  # actually sends the first tweets to twitter for retweeting(voting)
  def create_master_tweets
    begin
      
      # put urls into tweet
      inject_url_into_tweets
      
      # tweet it!
      return false unless tweet_master("up")
      
      # if downvoting enabled tweet downvote as well
      if self.is_pool 
      
        # tweet it!
        return false unless tweet_master("down")
      
        # cast owner's vote
        self.owner_vote == "up" ? self.upvote_by(self.user) : self.downvote_by(self.user)

      else
      
        self.upvote_by(self.user)
      
      end
    
    rescue Exception => e
      ap "Proposal#create_master_tweets #{e.inspect}"
    end
    
  end
  
  # clean up master's timeline
  def remove_from_twitter
    begin
      Twitocracy.master.status_destroy(self.up_tweetid) if self.up_tweetid    
      Twitocracy.master.status_destroy(self.down_tweetid) if self.down_tweetid       
    rescue Exception => e
      ap "Proposal#remove_from_twitter #{e.inspect}"
    end
  end
  
  def tweet_master(dir)
    if tweet_id = Twitocracy.master.tweet(self.send("#{dir}_tweet")).id
      self.update(:"#{dir}_tweetid" => tweet_id) 
    else
      self.errors.add(:base, "Sorry, your proposal has not been created")  
      raise ActiveRecord::Rollback "Sorry, your proposal has not been created"
      false
    end
  end
  
  def validate_count_against_rate_limit
    errors.add(:base, "you can have maximum #{MAX_COUNT_PER_USER} open proposals at the same time") if self.user.proposals.open.count >= MAX_COUNT_PER_USER
  end
  
  def validate_started_at
    if self.started_at
      errors.add(:started_at, "must be on or after today") unless is_date_on_or_after_now(self.started_at)
    end
  end
  
  def validate_finished_at
    if self.started_at && self.finished_at
      errors.add(:finished_at, "must be on or after today") unless is_date_on_or_after_now(self.finished_at)
      errors.add(:finished_at, "must be greater then start date") if self.finished_at <= self.started_at
    end
  end  
  
  def validate_up_down_tweet_diff
    errors.add(:down_tweet, "must be different then up tweet") if self.up_tweet == self.down_tweet
  end
  
  def is_date_on_or_after_now(date)
    date >= Date.current
  end
  
end