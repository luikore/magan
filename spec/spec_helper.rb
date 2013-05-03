require_relative "../lib/magan"
require "rspec/core"
require "rspec/mocks"
require "rspec/autorun"
require "pry"

RSpec.configure do |config|
  config.expect_with :stdlib
  case config.formatters.first
  when RSpec::Core::Formatters::TextMateFormatter
    def puts *xs
      xs.each do |x|
        $stdout.puts "<pre style='word-wrap:break-word;word-break:break-all;'>#{CGI.escape_html x.to_s}</pre>"
      end
    end

    def print *xs
      xs.each do |x|
        $stdout.print "<pre style='word-wrap:break-word;word-break:break-all;'>#{CGI.escape_html x.to_s}</pre>"
      end
    end

    def p *xs
      xs.each do |x|
        $stdout.puts "<pre style='word-wrap:break-word;word-break:break-all;'>#{CGI.escape_html x.inspect}</pre>"
      end
      xs
    end
  end
end

if false
class ExampleGrammar
  extend Magan
  grammar <<-RUBY
main = 'a'
  RUBY
end
end
