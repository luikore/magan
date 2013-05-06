module Magan
  module Nodes
    class Seq < ::Array
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
        map(&:to_re).join
      end

      def generate indent, wrap=true
        return "#{indent}@src.scan(%r\"#{to_re}\")\n" if literal?

        if wrap
          r = "#{indent}lambda {|;r_, e_|\n"
          inner_indent = indent + '  '
        else
          r = ''
          inner_indent = indent
        end

        r << inner_indent << "r_ = []\n"
        code = "#{inner_indent}e_ =
%s
#{inner_indent}return unless e_
#{inner_indent}r_ << e_
"
        e_indent = inner_indent + '  '
        each do |e|
          r << (code % e.generate(e_indent))
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
