module Magan
  module RuleNodes
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

      def vars
        flat_map &:vars
      end

      WRAP_OPEN = "lambda {|;r_|\n"
      WRAP_CLOSE = "}[]\n"

      def generate ct, wrap=true
        if literal?
          ct.add %Q|@src.scan(%r"#{to_re}")\n|
          return
        end

        if wrap
          ct.add WRAP_OPEN
          ct.push_indent
        end
        ct.add "r_ = Node.new\n"
        ct.add "r_.add(\n"

        *head, last = self
        head.each do |e|
          ct.child e
          ct.add ") and r_.add(\n"
        end
        ct.child last
        ct.add ")\n"

        if wrap
          ct.pop_indent
          ct.add WRAP_CLOSE
        end
      end
    end
  end
end
