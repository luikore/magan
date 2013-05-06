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

      WRAP_OPEN = "lambda {|;r_, e_|\n"
      WRAP_CLOSE = "}[]\n"
      INIT_R = "r_ = []\n"

      def generate ct, wrap=true
        if literal?
          ct.add %Q|@src.scan(%r"#{to_re}")\n|
          return
        end

        if wrap
          ct.add WRAP_OPEN
          ct.push_indent
        end
        ct.add INIT_R

        before = "#{ct.indent}e_ =\n"
        after = "#{ct.indent}return unless e_\n#{ct.indent}r_ << e_\n"
        ct.push_indent
        each do |e|
          ct << before
          e.generate ct
          ct << after
        end
        ct.pop_indent

        if wrap
          ct.pop_indent
          ct.add WRAP_CLOSE
        end
      end
    end
  end
end
