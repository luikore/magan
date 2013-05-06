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

      # note:
      #   for '?', the result is [r_] or []
      #   for '*' and '+', the result is r_
      def generate indent, wrap=true
        return "#{indent}@src.scan(%r\"#{to_re}\")" if literal?

        if var
          assign =
            if var.end_with?('::')
              "#{var[0...-2]} << r_; "
            else
              "#{var[0...-1]} = r_; "
            end
        end

        if wrap
          r = "#{indent}lambda{|;r_, e_|\n"
          inner_indent = indent + '  '
        else
          r = ''
          inner_indent = indent
        end

        case quantifier
        when '?'
          r << "#{inner_indent}@src.push
#{inner_indent}r_ =
#{atom.generate inner_indent + '  '}
#{inner_indent}if r_ then #{assign} @src.drop; [r_] else @src.pop; [] end"

        when '*', '+'
          case quantifier
          when '*'
            r << "#{inner_indent}r_ = []\n"
          else
            r << "#{inner_indent}e_ =
#{atom.generate inner_indent + '  '}
#{inner_indent}return unless e_
#{inner_indent}r_ = [e_]
"
          end
          r << "#{inner_indent}#{assign}
#{inner_indent}loop do
#{inner_indent}  @src.push
#{inner_indent}  e_ =
#{atom.generate inner_indent + '    '}
#{inner_indent}  if e_ then @src.drop; r_ << e_ else @src.pop; break; end
#{inner_indent}end
#{inner_indent}r_
"
        else
          r << "#{inner_indent}r_ =
#{atom.generate inner_indent + '  '}
#{inner_indent}if r_ then #{assign} r_; end
"
        end

        if wrap
          r << indent << "}[]"
        else
          r
        end
      end
    end
  end
end
