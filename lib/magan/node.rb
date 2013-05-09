module Magan
  class Node < Array
    BLANK = ''.freeze

    QUANTIFIER_MAP = {
      '?'.freeze => 'maybe'.freeze,
      '*'.freeze => 'star'.freeze,
      '+'.freeze => 'plus'.freeze
    }.freeze

    def initialize
      super
      @value = self
    end
    attr_accessor :value

    def add e
      self << e if e
    end

    def maybe src
      src.push
      e = yield
      if e
        src.drop
        self << e
      else
        src.pop
        self
      end
    end

    def star src
      loop do
        src.push
        e = yield
        if e and e != BLANK
          src.drop
          self << e
        else
          src.pop
          break
        end
      end
      self
    end

    def plus src
      e = yield
      return unless e
      self << e
      loop do
        src.push
        e = yield
        if e and e != BLANK
          src.drop
          self << e
        else
          src.pop
          break
        end
      end
      self
    end
  end
end
