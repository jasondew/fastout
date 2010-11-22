require "rubygems"
require "bundler"
Bundler.setup

require "fastout"

Rspec.configure do |config|
  config.mock_with :rr
end
