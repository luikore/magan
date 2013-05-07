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

      # note:
      #   for '?', the result is [r_] or []
      #   for '*' and '+', the result is r_
      def generate ct, wrap=true
        if var
          assign =
            if var.end_with?('::')
              "#{var[0...-2]} << "
            else
              "#{var[0...-1]} = "
            end
        end

        if atom.literal?
          return ct.add %Q|(#{assign}@src.scan(%r"#{to_re}"))\n|
        end

        node_method = Node::QUANTIFIER_MAP[quantifier]
        if atom.is_a?(Seq)
          ct.add "(#{assign}Node.new.#{node_method}(@src){|;r_|\n"
        else
          ct.add "(#{assign}Node.new.#{node_method}(@src){\n"
        end
        ct.push_indent
        atom.generate ct, false
        ct.pop_indent
        ct.add "})\n"
      end
    end
  end
end
