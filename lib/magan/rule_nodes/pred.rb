module Magan
  module RuleNodes
    Pred = S.new :prefix, :atom, :quantifier
    class Pred
      def literal?
        atom.literal?
      end

      def to_re
        if quantifier
          "(?#{PRED_TO_RE[prefix]}(?:#{atom.to_re})#{QUANTIFIER_TO_RE[quantifier]})"
        else
          "(?#{PRED_TO_RE[prefix]}#{atom.to_re})"
        end
      end

      def vars
        atom.vars
      end

      def max_capture_depth base
        atom.max_capture_depth base
      end

      BRACE_CLOSE = "}.tap{ @src.pop } && [])\n"
      PAREN_OPEN  = "(@src.push;(\n"
      PAREN_CLOSE = ").tap{ @src.pop } && [])\n"

      # note: parser ensures that quantifier can never be '?' or '*'
      def generate ct
        if literal?
          ct.add %Q|(@src.match_bytesize(%r"#{to_re}") && [])\n|
          return
        end

        if quantifier
          zscan_method = QUANTIFIER_TO_ZSCAN[quantifier]
          ct.add "(@src.push; @src.#{zscan_method}(Node.new){\n"
          ct.push_indent
          atom.generate ct
          ct.pop_indent
          ct.add BRACE_CLOSE
        else
          ct.add PAREN_OPEN
          ct.child atom
          ct.add PAREN_CLOSE
        end
      end
    end
  end
end
