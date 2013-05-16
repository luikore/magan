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
        first_vars = first.vars
        if first_vars.empty?
          ct.add FIRST_OPEN
          ct.child first
          ct.add TRY_CLOSE
        else
          ct.add "(vars.try(#{Vars.init_add_values_s first_vars}){@src.try{\n"
          ct.child first
          ct.add "}} or\n"
        end
        es.each do |e|
          e_vars = e.vars
          if e_vars.empty?
            ct.add TRY_OPEN
            ct.child e
            ct.add TRY_CLOSE
          else
            ct.add "vars.try(#{Vars.init_add_values_s e_vars}){@src.try{\n"
            ct.child e
            ct.add "}} or\n"
          end
        end
        ct.child last
        ct.add LAST_CLOSE
      end
    end
  end
end
