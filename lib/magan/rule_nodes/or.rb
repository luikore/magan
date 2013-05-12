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

      FIRST_OPEN = "(@src.try{\n"
      TRY_OPEN = "@src.try{\n"
      TRY_CLOSE = "} or\n"
      LAST_CLOSE = ")\n"

      def generate ct
        if literal?
          Re[to_re].generate ct
          return
        end

        first, *es, last = self
        ct.add FIRST_OPEN
        ct.child first
        ct.add TRY_CLOSE
        es.each do |e|
          ct.add TRY_OPEN
          ct.child e
          ct.add TRY_CLOSE
        end
        ct.child last
        ct.add LAST_CLOSE
      end
    end
  end
end
