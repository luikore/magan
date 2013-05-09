module Magan
  class StringNode < String
    def self.new s
      if s
        node = super(s)
        node.value = node
      end
    end

    def value= v
      @value = v
    end
    attr_reader :value
  end
end
