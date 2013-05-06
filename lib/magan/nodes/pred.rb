module Magan
  module Nodes
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

      # note: parser ensures that quantifier can never be '?' or '*'
      def generate indent, wrap=true
        return "#{indent}(@src.match_bytesize(%r\"#{to_re}\") ? [] : nil)" if literal?

        if wrap
          r = "#{indent}lambda{|;r_, e_|\n"
          inner_indent = indent + '  '
        else
          r = ''
          inner_indent = indent
        end

        r << "#{inner_indent}@src.push\n"
        r << Unit[nil, atom, quantifier].generate(inner_indent, false)
        r << "#{inner_indent}if r_
#{inner_indent}  @src.pop
#{inner_indent}  []
#{inner_indent}else
#{inner_indent}  @src.drop
#{inner_indent}  nil
#{inner_indent}end
"
        if wrap
          r << "#{indent}}[]"
        else
          r
        end
      end
    end
  end
end