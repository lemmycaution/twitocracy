class Proposal < ActiveRecord::Base
  
  DEFAULT_LIMIT = 8
  MAX_COUNT_PER_USER = 12
  SHORT_URL_LENGTH = 23
  TWEET_LENGTH = 140
  PROPOSAL_TWEET_LENGTH = TWEET_LENGTH - SHORT_URL_LENGTH
  
  belongs_to :user
  
  validates_presence_of :user_id, :subject, :up_tweet, :started_at, :finished_at
  validates_presence_of :down_tweet, if: lambda { |proposal| proposal.is_pool }  
  
  validates_length_of :subject,     maximum: PROPOSAL_TWEET_LENGTH, if: lambda { |proposal| !proposal.is_pool }
  validates_length_of :up_tweet,    maximum: PROPOSAL_TWEET_LENGTH
  validates_length_of :down_tweet,  maximum: PROPOSAL_TWEET_LENGTH, if: lambda { |proposal| proposal.is_pool }  
  
  validate :validate_up_down_tweet_diff, if: lambda { |proposal| proposal.is_pool }    
  validate :validate_started_at
  validate :validate_finished_at
  validate :validate_count_against_rate_limit
  
  before_validation :generate_up_tweet_from_subject, if: lambda { |proposal| !proposal.is_pool }  
  
  before_destroy    :remove_from_twitter
  
  after_create  :create_master_tweets
  after_create  lambda { |p| p.push(:create) }
  after_update  lambda { |p| p.push(:update) }
  after_destroy lambda { |p| p.push(:destroy) }
  
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
  
  attr_accessor :downvoting_enabled
  attr_accessor :owner_vote  
  
  %w(up down).each do |dir|
    class_eval <<-CODE 
    
    def #{dir}vote_by(user)
      
        begin
          
          reversedir_tweetid = self.#{dir == "up" ? "down" : "up"}_tweetid
          if reversedir_tweetid.present? 
            ap user.screenname
            begin
              reverse_tweet = user.status_get(reversedir_tweetid)
              if reverse_tweet.retweeted
                self.errors.add(:base, "You have already voted on this proposal")  
                return false
              end
            rescue Twitter::Error::NotFound  
              # self.update_attributes(#{dir == "up" ? "down" : "up"}_tweetid: nil)
              self.errors.add(:base, "Proposal has not been found")  
              return false
            end
          end
          
          tweets = user.status_retweet(self.#{dir}_tweetid)
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
  
  def owner
    self.user.screenname
  end
  
  def is_pool
    self.persisted? ? self.down_tweet.present? : self.downvoting_enabled.present?
  end
  
  def is_open
    self.started_at < Time.now.at_end_of_day and self.finished_at > Time.now.beginning_of_day
  end
  
  def upvote_count
    self.up_retweet_count
  end
  
  def downvote_count
    self.down_retweet_count
  end
  
  def push(event)
    Pusher[event == :create ? 'proposals' : "proposal-#{self.id}"].trigger(event, self.as_json)
  end
  
  def public_url
    "http://twitocracy.herokuapp.com/#{self.id}"
  end
  
  private

  def generate_up_tweet_from_subject
    self.up_tweet = self.subject
  end
  
  def inject_url_into_tweets
    self.up_tweet   = "#{self.up_tweet} #{public_url}" if !self.up_tweet.include?(public_url)
    self.down_tweet = "#{self.down_tweet} #{public_url}" if self.is_pool && !self.down_tweet.include?(public_url)
  end
  
  def create_master_tweets
    begin
      
      inject_url_into_tweets
      
      if tweet_id = Twitocracy.master.status_update(self.up_tweet).id
        self.update(up_tweetid: tweet_id) 
      else
        self.errors.add(:base, "Sorry, your proposal has not been created")  
        return false
      end
    
      if self.is_pool 
      
        if tweet_id = Twitocracy.master.status_update(self.down_tweet).id
          self.update(down_tweetid: tweet_id) 
        else
          self.errors.add(:base, "Sorry, your proposal has not been created")  
          return false
        end
      
      
        if self.owner_vote == "up"
          self.upvote_by(self.user)
        else
          self.downvote_by(self.user)
        end
      
      else
      
        self.upvote_by(self.user)
      
      end
    
    rescue Exception => e
      ap "Proposal#create_master_tweets #{e.inspect}"
    end
  end
  
  def remove_from_twitter
    begin
      Twitocracy.master.status_destroy(self.up_tweetid) if self.up_tweetid    
      Twitocracy.master.status_destroy(self.down_tweetid) if self.down_tweetid       
    rescue Exception => e
      ap "Proposal#remove_from_twitter #{e.inspect}"
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