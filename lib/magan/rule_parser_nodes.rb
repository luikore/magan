module Magan
  class RuleParser
    Unit = Struct.new :atom, :qualifier, :var

    Pred = Struct.new :prefix, :atom, :qualifier

    # for anchors / char groups / strings
    Re = Struct.new :re
    class Re

    end

    Ref = Struct.new :id

    BackRef = Struct.new :var

    # seq is represented in an array
    Or = Struct.new :branches
    class Or

    end

    Helper = Struct.new :helper, :args
    class Helper

    end

    Rule = Struct.new :name, :expr, :block
    class Rule
      def generate
      end
    end
  end
end
