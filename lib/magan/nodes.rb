module Magan
  module Nodes
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

    QUANTIFIER_TO_RE = {
      '*' => '*+',
      '+' => '++',
      '?' => '?+',
      '**' => '*',
      '+*' => '+',
      '?*' => '?',
      '*?' => '*?',
      '+?' => '+?',
      '??' => '??'
    }

    PRED_TO_RE = {
      '&' => '=',
      '!' => '!',
      '<&' => '<=',
      '<!' => '<!'
    }

    class Success
      def literal?
        true
      end

      def to_re
        ''
      end

      def generate indent, wrap=true
        '[]'
      end
    end

    class Fail
      def literal?
        true
      end

      def to_re
        '(?:(?=\A)\A)'
      end

      def generate indent, wrap=true
        'nil'
      end
    end

    # for anchors / char groups / strings
    Re = S.new :re
    class Re
      def literal?
        true
      end

      alias to_re re

      def generate indent, wrap=true
        "#{indent}@src.scan(%r\"#{re}\")"
      end
    end

    Ref = S.new :id
    class Ref
      def literal?
        false
      end

      def generate indent, wrap=true
        "#{indent}parse_#{id}()"
      end
    end

    BackRef = S.new :var
    class BackRef
      def literal?
        false
      end

      def generate indent, wrap=true
        # todo
      end
    end

    Helper = S.new :helper, :args
    class Helper
      def literal?
        false
      end

      # no to_re

      def generate indent, wrap=true
        # todo
      end
    end

    Rule = S.new :name, :expr, :block
    class Rule
      def generate
        expr.generate '    ', false
      end
    end
  end

  class RuleParser
    include Nodes
  end
end
