module Magan
  class StringNode < String
    def self.new s
      if s
        node = super(s)
        node.value = node
      end
    end

    attr_accessor :value
  end
end
