module Magan
  module RuleNodes
    Unit = S.new :var, :atom, :quantifier
    class Unit
      def literal?
        return @literal unless @literal.nil?
        @literal = (!var and atom.literal?)
      end

      def to_re
        return atom.to_re unless quantifier
        "(?:#{atom.to_re})#{QUANTIFIER_TO_RE[quantifier]}"
      end

      def vars
        r = atom.vars
        r << var if var
        r
      end

      CLOSE               = "})\n"
      NO_QUANTIFIER_OPEN  = "(\n"
      NO_QUANTIFIER_CLOSE = ")\n"

      # note: result is array for ?, *, +
      def generate ct
        if var
          assign =
            if var.end_with?('::')
              "#{var[0...-2]} << "
            else
              "#{var[0...-1]} = "
            end
        end

        if atom.literal?
          if assign
            ct.add %Q|(#{assign}StringNode.new(@src.scan %r"#{to_re}"))\n|
          else
            Re[to_re].generate ct
          end
          return
        end

        unless quantifier
          # raise 'unexpected unit with no var no quantifier' unless assign
          ct.add "#{assign}(\n"
          ct.child atom
          ct.add ")\n"
          return
        end

        zscan_method = QUANTIFIER_TO_ZSCAN[quantifier]
        ct.add "(#{assign}@src.#{zscan_method}(Node.new){\n"
        ct.push_indent
        atom.generate ct
        ct.pop_indent
        ct.add CLOSE
      end
    end
  end
end
