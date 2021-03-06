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

    def self.freeze_hash hash
      hash.each do |k, v|
        k.freeze
        v.freeze
      end
      hash.freeze
    end

    QUANTIFIER_TO_RE = freeze_hash\
      '*' => '*+',
      '+' => '++',
      '?' => '?+',
      '**' => '*',
      '+*' => '+',
      '?*' => '?',
      '*?' => '*?',
      '+?' => '+?',
      '??' => '??'

    PRED_TO_RE = freeze_hash\
      '&' => '=',
      '!' => '!',
      '<&' => '<=',
      '<!' => '<!'

    QUANTIFIER_TO_ZSCAN = freeze_hash\
      '?' => 'zero_or_one',
      '*' => 'zero_or_more',
      '+' => 'one_or_more'

    module NoVar
      def vars
        []
      end

      def max_capture_depth base
        base
      end
    end

    class Success
      def literal?
        true
      end

      def to_re
        ''
      end

      include NoVar

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

      include NoVar

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

      include NoVar

      def generate ct
        ct.add %Q|@src.scan(%r"#{re}")\n|
      end
    end

    Ref = S.new :id
    class Ref
      def literal?
        false
      end

      include NoVar

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

      def max_capture_depth base
        # todo
        base
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

      def max_capture_depth base
        # todo
        base
      end

      def generate ct
        # some_helper.call @src, ->{
        #   arg1
        # }, ->{
        #   arg2
        # }, ...
        # some_helper = -> src, p1, p2, ...{
        #   @indent = src.scan
        # }
        # todo
      end
    end

    class DefinitionError < RuntimeError
    end

    Rule = S.new :name, :expr, :block, :line_index, :block_line_index
    class Rule
      def self.[] *xs
        new *xs
      end

      def initialize name, expr, block, line_index, block_line_index
        super(name, expr, block, line_index, block_line_index)
        @vars = expr.vars
        @capture_depth = 0
        @max_capture_depth = expr.max_capture_depth 1
        @vars.uniq!
        var_group = @vars.group_by{|v| v[/\w+/] }
        ambig_var, _ = var_group.find do |_, vs|
          vs.size > 1
        end
        if ambig_var
          raise DefinitionError, "ambiguous var definition: #{ambig_var}, it should stick to one type"
        end
      end
      attr_accessor :capture_depth

      def compute_var_i var
        @vars.size * @capture_depth + @vars.index(var)
      end

      def acc_var_ids
        ids = []
        @vars.each_with_index{|v, i|
          if v.end_with?('::')
            ids << i
          end
        }
        ids
      end

      def generate ct
        ct.current_rule = self
        if block or !@vars.empty?
          ct.add "captures = Captures.new #{@vars.size}, #{@max_capture_depth}, #{acc_var_ids}\n"
        end

        if block
          ct.add "if ast = \n"
          ct.push_indent
        end

        if expr.literal?
          ct.add %Q|StringNode.new(@src.scan %r"#{expr.to_re}")\n|
        else
          expr.generate ct
        end

        if block
          ct.pop_indent
            ct.push_indent
            if @vars.empty?
              ct.add "ast.value = exec_#{name} ast\n"
            else
              ct.add "ast.value = exec_#{name} ast, captures.get\n"
            end
            ct.add "ast\n"
            ct.pop_indent
          ct.add "end\n"
        end
      end

      def generate_parse ct, trace=false
        ct.add "def parse_#{name}\n"
        ct.add "  print %Q|#{name}: \#{@src.pos}: |\n" if trace
        ct.child self
        ct.add "  .tap{|o| p o}\n" if trace
        ct.add "end\n\n"
      end

      # if ct == nil, return a string
      def generate_exec ct
        return nil unless block

        unless @vars.empty?
          vars_aref_list = @vars.map{|var| var[/\w+/] }.join ', '
          vars_aref_list = ", (#{vars_aref_list})"
        end
        sig = "def exec_#{name} ast#{vars_aref_list}\n"

        if ct
          ct.add sig
          ct.push_indent
          ct.add_lines block
          ct.pop_indent
          ct.add "end\n\n"
        else
          sig << block << "\nend"
        end
      end
    end
  end

  class RuleParser
    include RuleNodes
  end
end
