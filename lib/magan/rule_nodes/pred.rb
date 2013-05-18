module Magan
  module RuleNodes
    Pred = S.new :prefix, :unit
    class Pred
      def literal?
        unit.literal?
      end

      def to_re
        "(?#{PRED_TO_RE[prefix]}#{unit.to_re})"
      end

      def vars
        unit.vars
      end

      def max_capture_depth base
        unit.max_capture_depth base
      end

      # note: parser ensures that quantifier can never be '?' or '*'
      def generate ct
        if unit.literal?
          ct.add %Q|(@src.match_bytesize(%r"#{to_re}") && StringNode.new(''))\n|
          return
        end

        ct.add "(@src.push;#{prefix['!']}(\n"
        ct.child unit
        ct.add ").tap{ @src.pop } && StringNode.new(''))\n"
      end
    end
  end
end
