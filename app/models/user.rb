class User < ActiveRecord::Base
  scope :online, -> { where("suid is not null") }
  has_many :proposals
  has_many :retweets
end
