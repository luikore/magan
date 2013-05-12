module Magan
  module RuleNodes
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

    QUANTIFIER_TO_ZSCAN = {
      '?'.freeze => 'zero_or_one'.freeze,
      '*'.freeze => 'zero_or_more'.freeze,
      '+'.freeze => 'one_or_more'.freeze
    }.freeze

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

      def generate ct
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

      def generate ct
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

      def generate ct
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

      def generate ct
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

      def generate ct
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

      def generate ct
        # todo
      end
    end

    class DefinitionError < RuntimeError
    end

    Rule = S.new :name, :expr, :block
    class Rule
      def generate ctx
        vars = expr.vars
        vars.map!{|v| [v[/^\w+/], v[/:+$/]] }
        if repeated_agg_vars = vars.select{|v| v.last == '::'}.uniq!
          raise DefinitionError, "repeated aggregate vars: #{repeated_agg_vars.join ' '}"
        end

        vars.uniq!
        var_group = vars.group_by(&:first)
        ambig_var, _ = var_group.find do |_, vs|
          vs.size > 1
        end
        if ambig_var
          raise DefinitionError, "ambiguous var definition: #{ambig_var}, it should stick to one type"
        end

        vars.each do |name, ty|
          if ty == '::'
            ctx.add "#{name} = []\n"
          else
            ctx.add "#{name} = nil\n"
          end
        end

        if block
          ctx.add "if ast = ast_ = (\n"
          ctx.push_indent
        end
        if expr.literal?
          ctx.add %Q|StringNode.new(@src.scan %r"#{expr.to_re}")\n|
        else
          expr.generate ctx
        end
        if block
          ctx.pop_indent
          ctx.add ")\n"
            ctx.push_indent
            vars.each do |name, ty|
              if ty == '::'
                ctx.add "#{name}.compact!\n"
                ctx.add "#{name}.map! &:value\n"
              else
                ctx.add "#{name} = #{name}.value if #{name}\n"
              end
            end
            ctx.add "ast_.value = (\n"
              ctx.push_indent
              ctx.add_lines block
              ctx.pop_indent
            ctx.add ")\n"
            ctx.add "ast_\n"
            ctx.pop_indent
          ctx.add "end\n"
        end
      end
    end
  end

  class RuleParser
    include RuleNodes
  end
end
