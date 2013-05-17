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

      # note: result is array for ?, *, +
      def generate ct
        if var
          assign =
            if var.end_with?('::')
              "captures.add(:#{var[0...-2]}, "
            else
              "captures.assign(:#{var[0...-1]}, "
            end
          assign_end = ")"
        end

        if atom.literal?
          if assign
            ct.add %Q<#{assign}(StringNode.new @src.scan %r"#{to_re}")#{assign_end}\n>
          else
            Re[to_re].generate ct
          end
          return
        end

        if quantifier
          zscan_method = QUANTIFIER_TO_ZSCAN[quantifier]
          atom_vars = atom.vars
          unless atom_vars.empty?
            vars_try_beg = "captures.try(#{Captures.init_add_values_s atom_vars}){"
            vars_try_end = '}'
          end
          ct.add "#{assign}@src.#{zscan_method}(Node.new){#{vars_try_beg}\n"
          ct.child atom
          ct.add "#{vars_try_end}}#{assign_end}\n"
        else
          # raise 'unexpected unit with no var no quantifier' unless assign
          ct.add "#{assign}(\n"
          ct.child atom
          ct.add ")#{assign_end}\n"
        end
      end
    end
  end
end
