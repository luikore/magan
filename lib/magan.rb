require "strscan"
require "ripper"
require "yaml"
require_relative "magan/rule_parser_nodes"
require_relative "magan/rule_parser"
require_relative "magan/first_block_stripper"

module Magan
  VERSION = '0.1'

  attr_reader :rules, :entrance

  def self.extended klass
    klass.class_eval <<-RUBY
      def initialize src
        @src = src
      end
    RUBY
  end

  # it's easy to write include instead of extend, so make it more robust
  def self.included klass
    klass.extend self
  end

  def grammar grammar_src
    raise 'need a class' unless is_a?(Class)
    @rules = RulesParser.new(grammar_src).parse
    @generated = {}
    @rules.each do |name, _|
      @generated[name] = false
    end
    generate_grammar
  end

  def compile entrance=:main
    @entrance = entrance.to_s[/(?!\d)\w+/]
    raise "invalid entrance: #{entrance.inspect}, should be a rule name" unless @entrance

    # update only changed ones
    code = ''
    @generated.each do |name, generated|
      unless generated
        code = @rules[name].generate
        code << <<-RUBY << "\n"
          def parse_#{name}
            #{code}
          end
        RUBY
        @generated[name] = true
      end
    end

    code << "alias parse parse_#@entrance"
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
