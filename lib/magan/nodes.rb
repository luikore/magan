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

    class CodeGenerateContext < Array
      def initialize indent
        @indent = indent
        super()
      end
      attr_reader :indent

      def push_indent
        @indent += '  '
      end

      def pop_indent
        @indent = @indent[0...-2]
      end

      def add line
        # raise "bad line" unless line.end_with?("\n")
        self << @indent << line
      end

      def child node
        outer_indent = @indent
        @indent += '  '
        node.generate self
        @indent = outer_indent
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

      def vars
        []
      end

      def generate ct, wrap=true
        "[]\n"
      end
    end

    class Fail
      def literal?
        true
      end

      def to_re
        '(?:(?=\A)\A)'
      end

      def vars
        []
      end

      def generate ct, wrap=true
        "nil\n"
      end
    end

    # for anchors / char groups / strings
    Re = S.new :re
    class Re
      def literal?
        true
      end

      alias to_re re

      def vars
        []
      end

      def generate ct, wrap=true
        ct.add %Q|@src.scan(%r"#{re}")\n|
      end
    end

    Ref = S.new :id
    class Ref
      def literal?
        false
      end

      def vars
        []
      end

      def generate ct, wrap=true
        ct.add "parse_#{id}()\n"
      end
    end

    BackRef = S.new :var
    class BackRef
      def literal?
        false
      end

      def vars
        # todo: this right?
        [var]
      end

      def generate ct, wrap=true
        # todo
      end
    end

    Helper = S.new :helper, :args
    class Helper
      def literal?
        false
      end

      def vars
        args.flat_map &:vars
      end

      def generate ct, wrap=true
        # todo
      end
    end

    Rule = S.new :name, :expr, :block
    class Rule
      def generate
        ctx = CodeGenerateContext.new '    '

        vars = expr.vars
        vars.uniq!
        vars.map!{|v| [v[/^\w+/], v[/:+$/]] }
        var_group = vars.group_by(&:first)
        ambig_var, _ = var_group.find do |_, vs|
          vs.size > 1
        end
        if ambig_var
          raise "ambiguous var definition: #{ambig_var}, it should stick to one type"
        end

        vars.each do |var|
          if var.end_with?('::')
            ctx.add "#{var[0...-2]} = []\n"
          else
            ctx.add "#{var[0...-1]} = nil\n"
          end
        end

        expr.generate ctx, false
        ctx.join
      end
    end
  end

  class RuleParser
    include Nodes
  end
end
