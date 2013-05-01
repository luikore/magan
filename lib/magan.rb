require "strscan"
require "ripper"
require_relative "magan/rule"
require_relative "magan/rule_parser"
require_relative "magan/first_block_stripper"

module Magan
  VERSION = '0.1'

  attr_reader :rules, :entrance

  def self.extended klass
    set_entrance :main
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

  # set entrance rule (default is :main)
  def set_entrance rule
    @entrance = rule
    @entrance_tainted = true
  end

  def compile
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

    if @entrance_tainted
      code << "alias parse parse_#@entrance"
      @entrance_tainted = false
    end

    unless code.empty?
      class_eval code
    end
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
