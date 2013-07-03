require "lib/twitocracy/client"

class User < ActiveRecord::Base
  
  # incldue twitter client wrapper
  include Twitocracy::Client
  
  # scope for online users
  # suids storing in memcache server
  scope :online, -> { where("suid is not null") }
  
  # every user can have many proposals
  has_many :proposals
end
