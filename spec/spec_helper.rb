require "rubygems"
require "bundler"
Bundler.setup

require "fastout"

RSpec.configure do |config|
  config.mock_with :rr
end
