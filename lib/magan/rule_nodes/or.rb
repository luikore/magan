module Magan
  module RuleNodes
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

      def vars
        flat_map &:vars
      end

      WRAP_OPEN = "(\n"
      WRAP_CLOSE = ")\n"
      TRY_OPEN = "@src.try{\n"
      TRY_CLOSE = "} ||\n"

      def generate ct
        if literal?
          ct.add %Q|@src.scan(%r"#{to_re}")\n|
          return
        end

        ct.add WRAP_OPEN
        ct.push_indent

        *es, last = self
        es.each do |e|
          ct.add TRY_OPEN
          ct.push_indent
          e.generate ct
          ct.pop_indent
          ct.add TRY_CLOSE
        end
        last.generate ct

        ct.pop_indent
        ct.add WRAP_CLOSE
      end
    end
  end
end
