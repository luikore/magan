require_relative "../lib/magan"
require "rspec/core"
require "rspec/mocks"
require "rspec/autorun"
require "pry"

RSpec.configure do |config|
  config.expect_with :stdlib
end

if false
class ExampleGrammar
  extend Magan
  grammar <<-RUBY
main = 'a'
  RUBY
end
end