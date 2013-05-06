module Magan
  module Nodes
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

      WRAP_OPEN  = "lambda{|;r_, e_|\n"
      WRAP_CLOSE = "}[]\n"
      MANY_OPEN  = [
        "loop do\n",
        "  @src.push\n",
        "  e_ =\n"
      ]
      MANY_CLOSE = [
        "  if e_ then @src.drop; r_ << e_ else @src.pop; break; end\n",
        "end\n",
        "r_\n"
      ]

      # note:
      #   for '?', the result is [r_] or []
      #   for '*' and '+', the result is r_
      def generate ct, wrap=true
        if literal?
          return ct.add %Q|@src.scan(%r"#{to_re}")\n|
        end

        if var
          assign =
            if var.end_with?('::')
              "#{var[0...-2]} << r_; "
            else
              "#{var[0...-1]} = r_; "
            end
        end

        if wrap
          ct.add WRAP_OPEN
          ct.push_indent
        end

        case quantifier
        when '?'
          ct.add "@src.push\n"
          ct.add "r_ =\n"
          ct.push_indent
          atom.generate ct
          ct.pop_indent
          ct.add "if r_ then #{assign} @src.drop; [r_] else @src.pop; [] end\n"

        when '*', '+'
          case quantifier
          when '*'
            ct.add "r_ = []\n"
          else
            ct.add "e_ =\n"
            ct.child atom
            ct.add "return unless e_\n"
            ct.add "r_ = [e_]\n"
          end
          if assign
            ct.add assign + "\n"
          end
          MANY_OPEN.each{|line| ct.add line }
          ct.child atom
          MANY_CLOSE.each{|line| ct.add line }

        else
          ct.add "r_ =\n"
          ct.child atom
          ct.add "if r_ then #{assign} r_; end\n"
        end

        if wrap
          ct.pop_indent
          ct.add WRAP_CLOSE
        end
      end
    end
  end
end
