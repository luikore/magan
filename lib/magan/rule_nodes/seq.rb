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

      WRAP_OPEN  = "(\n"
      WRAP_CLOSE = ")\n"
      LAST_CLOSE = ")\n"

      def generate ct
        if literal?
          ct.add %Q|@src.scan(%r"#{to_re}")\n|
          return
        end

        ct.add WRAP_OPEN
        ct.push_indent
        seq = ct.alloc

        ct.add "#{seq} = Node.new\n"
        ct.add "#{seq}.add(\n"
        *head, last = self
        inter = ") and #{seq}.add(\n"
        head.each do |e|
          ct.child e
          ct.add inter
        end
        ct.child last
        ct.add LAST_CLOSE

        ct.free seq
        ct.pop_indent
        ct.add WRAP_CLOSE
      end
    end
  end
end
