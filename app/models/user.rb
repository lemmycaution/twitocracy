require "lib/twitocracy/twitter_user"
class User < ActiveRecord::Base
  include Twitocracy::TwitterUser
  scope :online, -> { where("suid is not null") }
  has_many :proposals
end
