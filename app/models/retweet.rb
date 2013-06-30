class Retweet < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal
  validates_presence_of :retweetid, :user_id, :dir
end