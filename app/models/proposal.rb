require "lib/twitocracy/tw_client"

class Proposal < ActiveRecord::Base
  
  # DEFAULT_LIMIT = 10
  
  belongs_to :user
  has_many   :retweets, dependent: :destroy
  has_many   :retweeters, through: :retweets
  
  validates_presence_of :user_id, :subject, :up_tweet, :started_at, :finished_at
  validates_presence_of :down_tweet, if: lambda { |proposal| proposal.is_pool }  
  
  validates_length_of :subject, maximum: 140, if: lambda { |proposal| !proposal.is_pool }
  validates_length_of :up_tweet, maximum: 140
  validates_length_of :down_tweet, maximum: 140, if: lambda { |proposal| proposal.is_pool }  
  
  before_validation :generate_up_tweet_from_subject, if: lambda { |proposal| !proposal.is_pool }  
  
  after_commit :post_to_twitter, on: :create, if: lambda { |proposal| !proposal.is_pool }
  
  before_destroy :remove_from_twitter
  
  after_create { |p| p.push(:create) }
  after_update { |p| p.push(:update) }
  after_destroy { |p| p.push(:destroy) }
  
  scope :latest,    -> { order(created_at: :desc) }
  scope :critical,  -> { order("ABS(finished_at - now())") }  
  scope :up,        -> { order(up_retweet_count: :desc) }    
  scope :down,      -> { order(down_retweet_count: :desc) }      
  scope :closed,    -> { where("finished_at < ?", Time.now.at_end_of_day) }      
  scope :open,      -> { where("started_at <= ? and finished_at > ?", Time.now.beginning_of_day, Time.now.at_end_of_day) }        
  # scope :page,      lambda {|page| limit(DEFAULT_LIMIT).offset((page-1)*DEFAULT_LIMIT) }  
  default_scope -> { latest }
  
  attr_accessor :downvoting_enabled
  
  %w(up down).each do |action|
    class_eval <<-CODE 
    def #{action}vote_by(user)
      if self.#{action}_tweetid.present?
        tweets = Twitocracy::TwClient.retweet(user, self.#{action}_tweetid)
        tweets.each do |tweet|
          if retweetid  = tweet.try(:retweeted_status).try(:id)
            user.retweets.create(proposal_id: self.id, retweetid:  retweetid, dir: "#{action}")
          end
          if retweet_count = tweet.try(:retweet_count)
            self.update_attributes(#{action}_retweet_count: retweet_count) 
          end
        end
      else
        tweet = Twitocracy::TwClient.tweet(user,self.#{action}_tweet)  
        self.update_attributes(#{action}_tweetid: tweet.id) unless tweet.try(:id).nil?
      end
      self
    end
    CODE
  end
  
  %w(up down).each do |dir|
    class_eval <<-CODE  
      def un_#{dir}vote_by(user)
        retweet = self.retweets.find_by(user_id: user.id, dir: "#{dir}")
        untweets = Twitocracy::TwClient.destroy(user, retweet.retweetid)
        untweets.each do |untweet|
          if retweet_count = untweet.try(:retweeted_status).try(:retweet_count)
            self.update_attributes(#{dir}_retweet_count: retweet_count) 
          end
        end
        retweet.destroy
        self
      end
    CODE
  end
  
  def as_json(options = {})
    if user = options.delete(:user)
      options = options.merge(methods: [:owner,:is_pool,:upvote_count,:downvote_count])
      json = super(options)
      json["up_retweeted"] = self.retweeted_by(user)
      json["down_retweeted"] = self.retweeted_by(user, "down")      
      json
    else
      options = options.merge(methods: [:owner,:is_pool,:upvote_count,:downvote_count])
      super(options)      
    end
  end
  
  def owner
    self.user.screenname
  end
  
  def is_pool
    self.persisted? ? self.down_tweet.present? : (self.downvoting_enabled == "true")
  end
  
  def upvote_count
    self.up_retweet_count + (self.up_tweetid ? 1 : 0)
  end
  
  def downvote_count
    self.down_retweet_count + (self.down_tweetid ? 1 : 0)
  end
  
  def retweeted_by(user, dir = "up")
    !self.retweets.where(dir: dir).find_by(user_id: user.id).nil?
    # self.retweeters.includes(:retweet).where(dir: dir).references(:retweets).include?(user)
  end
  
  def push(event)
    Pusher[event == :create ? 'proposals' : "proposal-#{self.id}"].trigger(event, self.as_json)
  end
  
  private
  
  def post_to_twitter
    tweet = Twitocracy::TwClient.tweet(self.user, self.up_tweet)
    ap tweet.to_json
    begin
      self.update_attributes(up_tweetid: tweet.id) unless tweet.try(:id).nil?
    rescue Exception => e
      ap e.inspect
    end    
  end
  
  def generate_up_tweet_from_subject
    self.up_tweet = self.subject
  end
  
  def remove_from_twitter
    begin
      Twitocracy::TwClient.destroy(self.user, self.up_tweetid) if self.up_tweetid    
      Twitocracy::TwClient.destroy(self.user, self.down_tweetid) if self.down_tweetid       
    rescue Exception => e
      ap e.inspect
    end
  end
  
end