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

      def max_capture_depth depth
        depth += 1 if (quantifier and var)
        atom.max_capture_depth depth
      end

      # note: result is array for ?, *, +
      def generate ct
        if var
          var_i = ct.current_rule.compute_var_i var
          assign =
            if var.end_with?('::')
              "captures.acc(#{var_i}, "
            else
              "captures.assign(#{var_i}, "
            end
          assign_end = ")"
          assign_comment = "# #{var}"
        end

        if atom.literal?
          if assign
            ct.add %Q<#{assign}(StringNode.new @src.scan %r"#{to_re}")#{assign_end} #{assign_comment}\n>
          else
            Re[to_re].generate ct
          end
          return
        end

        if quantifier
          zscan_method = QUANTIFIER_TO_ZSCAN[quantifier]
          atom_vars = atom.vars
          rule = ct.current_rule
          unless atom_vars.empty?
            rule.capture_depth += 1
            vars_try_beg = "captures.try(#{rule.capture_depth},"
            vars_try_end = ')'
          end
          ct.add "#{assign}@src.#{zscan_method}(Node.new){#{vars_try_beg}#{assign_comment}\n"
          ct.child atom
          unless atom_vars.empty?
            rule.capture_depth -= 1
          end
          ct.add "#{vars_try_end}}#{assign_end}\n"
        else
          # raise 'unexpected unit with no var no quantifier' unless assign
          ct.add "#{assign}#{assign_comment}\n"
          ct.child atom
          ct.add "#{assign_end}\n"
        end
      end
    end
  end
end
