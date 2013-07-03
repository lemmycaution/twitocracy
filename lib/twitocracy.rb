require 'lib/twitocracy/master'

module Twitocracy
  
  def self.master
    @master ||= Master.new
  end
  
end