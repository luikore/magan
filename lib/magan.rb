require "zscan"
require "ripper"
require "yaml"
require_relative "magan/rule_nodes"
require_relative "magan/rule_nodes/unit"
require_relative "magan/rule_nodes/pred"
require_relative "magan/rule_nodes/seq"
require_relative "magan/rule_nodes/or"
require_relative "magan/rule_parser"
require_relative "magan/rule_parser/first_block_stripper"

module Magan
  VERSION = '0.1'

  class Node < Array
    def initialize type
      @type = type
      super
    end
    attr_reader :type
  end

  attr_reader :rules, :entrance

  def self.included klass
    klass.class_eval <<-RUBY
      def initialize src
        @src = ZScan.new src
      end
    RUBY
    klass.extend self
  end

  def grammar grammar_src
    raise 'need a class' unless is_a?(Class)
    @rules = RuleParser.new(grammar_src).parse
    @generated = {}
    @rules.each do |name, _|
      @generated[name] = false
    end
  end

  def compile entrance=:main
    @entrance = entrance.to_s[/(?!\d)\w+/]
    raise "invalid entrance: #{entrance.inspect}, should be a rule name" unless @entrance

    # update only changed ones
    code = ''
    @generated.to_a.each do |(name, generated)|
      unless generated
        code_content = @rules[name].generate
        code << <<-RUBY << "\n"
  def parse_#{name}
#{code_content}
  end
        RUBY
        @generated[name] = true
      end
    end

    code << "  alias parse parse_#@entrance"
    class_eval code
  end

  def helper
    @helper ||= {}
  end

  def closure rule

  end

  def parse src
    new(src).parse
  end
end
