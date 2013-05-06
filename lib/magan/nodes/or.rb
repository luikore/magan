module Magan
  module Nodes
    class Or < ::Array
      def self.[] *xs
        r = new
        xs.each do |x|
          r << x
        end
        r
      end

      def literal?
        return @literal unless @literal.nil?
        @literal = all?(&:literal?)
      end

      def to_re
        map(&:to_re).join '|'
      end

      def generate indent, wrap=true
        return "#{indent}@src.scan(%r\"#{to_re}\")" if literal?

        if wrap
          r = "#{indent}lambda {|;r_|\n"
          inner_indent = indent + '  '
        else
          r = ''
          inner_indent = indent
        end

        r << "#{inner_indent}@src.push\n"
        *es, last = self
        code = "#{inner_indent}r_ =
%s
#{inner_indent}if r_
#{inner_indent}  @src.drop
#{inner_indent}  return r_
#{inner_indent}else
#{inner_indent}  @src.restore
#{inner_indent}end
"
        e_indent = inner_indent + '  '
        es.each {|e|
          r << (code % e.generate(e_indent))
        }
        r << last.generate(inner_indent, false) << "\n"

        r << "#{inner_indent}@src.drop\n"
        r << "#{inner_indent}r_\n"
        if wrap
          r << "#{indent}}[]"
        else
          r
        end
      end
    end
  end
end
