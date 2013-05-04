module Magan
  class RuleParser
    class S < Struct
      def inspect
        pretty_inspect # may not defined yet, don't alias
      end

      def pretty_print(q)
        q.group(1, sprintf("<%s", PP.mcall(self, Kernel, :class).name.split('::').last), '>') {
          q.seplist(PP.mcall(self, Struct, :members), lambda { q.text "" }) {|member|
            q.breakable
            q.text member.to_s
            q.text '='
            q.group(1) {
              q.breakable ''
              q.pp self[member]
            }
          }
        }
      end

      def pretty_print_cycle(q)
        q.text sprintf("<%s:...>", PP.mcall(self, Kernel, :class).name.split('::').last)
      end
    end

    Unit = S.new :var, :atom, :quantifier

    Pred = S.new :prefix, :atom, :quantifier

    # for anchors / char groups / strings
    Re = S.new :re
    class Re
    end

    Ref = S.new :id

    BackRef = S.new :var

    class Or < ::Array
    end

    class Seq < ::Array
    end

    Helper = S.new :helper, :args
    class Helper
    end

    Rule = S.new :name, :expr, :block
    class Rule
      def generate
      end
    end
  end
end
