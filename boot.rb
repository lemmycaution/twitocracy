$:.unshift File.dirname( __FILE__)
$stdout.sync = true

# Server needs
require "bundler/setup"
Bundler.require

if ENV['RACK_ENV'] == "development"
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 
end

require 'lib/hash'

require "app/api"