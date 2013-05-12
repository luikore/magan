module Magan
  class Node < Array
    def initialize
      super
      @value = self
    end
    attr_accessor :value

    def add e
      self << e if e
    end
  end
end
