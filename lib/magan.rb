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
require_relative "magan/extender"
require_relative "magan/code_gen_context"
require_relative "magan/node"
require_relative "magan/string_node"

module Magan
  VERSION = '0.1'

  def initialize src
    @src = ZScan.new src
  end
  attr_reader :src

  def self.included klass
    klass.extend Extender
  end
end
