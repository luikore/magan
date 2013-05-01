module Magan
  SeqExpr    = Struct.new :children
  class SeqExpr

  end

  OrExpr     = Struct.new :children
  class OrExpr

  end

  HelperExpr = Struct.new :id, :args
  class HelperExpr

  end

  Rule       = Struct.new :name, :expr, :block
  class Rule
    def generate
    end
  end
end
