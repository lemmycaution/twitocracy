$:.unshift File.dirname( __FILE__)
$stdout.sync = true

# Server needs
require "bundler/setup"
Bundler.require

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 

require 'lib/hash'

require "app/api"