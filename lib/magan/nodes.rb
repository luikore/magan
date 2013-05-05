module Magan
  class RuleParser
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

      Unit = S.new :var, :atom, :quantifier
      class Unit
        def literal?
          return @literal unless @literal.nil?
          @literal = (!var and atom.literal?)
        end

        def to_re
          return atom.to_re unless quantifier
          "(?:#{atom.to_re})#{QUANTIFIER_TO_RE[quantifier]}"
        end

        # note:
        #   for '?', the result is [r_] or []
        #   for '*' and '+', the result is r_
        def generate indent, wrap=true
          return "#{indent}@src.scan(/#{to_re}/)" if literal?

          if var
            assign =
              if var.end_with?('::')
                "#{var[0...-2]} << r_; "
              else
                "#{var[0...-1]} = r_; "
              end
          end

          if wrap
            r = "#{indent}lambda{|;r_, e_|\n"
            inner_indent = indent + '  '
          else
            r = ''
            inner_indent = indent
          end

          case quantifier
          when '?'
            r << "#{inner_indent}@src.push_pos
#{inner_indent}r_ =
#{atom.generate inner_indent + '  '}
#{inner_indent}if r_ then #{assign}; @src.drop_top; [r_] else @src.pop_pos; [] end"

          when '*', '+'
            case quantifier
            when '*'
              r << "#{inner_indent}r_ = []\n"
            else
              r << "#{inner_indent}e_ =
#{atom.generate inner_indent + '  '}
#{inner_indent}return unless e_
#{inner_indent}r_ = [e_]
"
            end
            r << "#{inner_indent}#{assign}
#{inner_indent}loop do
#{inner_indent}  @src.push_pos
#{inner_indent}  e_ =
#{atom.generate inner_indent + '    '}
#{inner_indent}  if e_ then @src.drop_top; r_ << e_ else @src.pop_pos; break; end
#{inner_indent}end
#{inner_indent}r_
"
          else
            r << "#{inner_indent}r_ =
#{atom.generate inner_indent + '  '}
#{inner_indent}if r_ then #{assign}; r_; end
"
          end

          if wrap
            r << indent << "}[]"
          else
            r
          end
        end
      end

      Pred = S.new :prefix, :atom, :quantifier
      class Pred
        def literal?
          atom.literal?
        end

        def to_re
          if quantifier
            "(?#{PRED_TO_RE[prefix]}(?:#{atom.to_re})#{QUANTIFIER_TO_RE[quantifier]})"
          else
            "(?#{PRED_TO_RE[prefix]}#{atom.to_re})"
          end
        end

        # note: parser ensures that quantifier can never be '?' or '*'
        def generate indent, wrap=true
          return "#{indent}(@src.scan(/#{to_re}/) ? [] : nil)" if literal?

          if wrap
            r = "#{indent}lambda{|;r_, e_|\n"
            inner_indent = indent + '  '
          else
            r = ''
            inner_indent = indent
          end

          r << "#{inner_indent}@src.push_pos\n"
          r << Unit[nil, atom, quantifier].generate(inner_indent, false)
          r << "#{inner_indent}if r_
#{inner_indent}  @src.pop_pos
#{inner_indent}  []
#{inner_indent}else
#{inner_indent}  @src.drop_top
#{inner_indent}  nil
#{inner_indent}end
"
          if wrap
            r << "#{indent}}[]"
          else
            r
          end
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
          "#{indent}@src.scan(/#{re}/)"
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

        def generate indent, wrap=true
          return "#{indent}@src.scan(/#{to_re}/)" if literal?

          if wrap
            r = "#{indent}lambda {|;r_|\n"
            inner_indent = indent + '  '
          else
            r = ''
            inner_indent = indent
          end

          r << "#{inner_indent}@src.push_pos\n"
          *es, last = self
          code = "#{inner_indent}r_ =
%s
#{inner_indent}if r_
#{inner_indent}  @src.drop_top
#{inner_indent}  return r_
#{inner_indent}else
#{inner_indent}  @src.pop_pos
#{inner_indent}end
"
          e_indent = inner_indent + '  '
          es.each {|e|
            r << (code % e.generate(e_indent))
          }
          r << last.generate(inner_indent, false) << "\n"

          if wrap
            r << "#{indent}}[]"
          else
            r
          end
        end
      end

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

        def generate indent, wrap=true
          return "#{indent}@src.scan(/#{to_re}/)\n" if literal?

          if wrap
            r = "#{indent}lambda {|;r_, e_|\n"
            inner_indent = indent + '  '
          else
            r = ''
            inner_indent = indent
          end

          r << inner_indent << "r_ = Array.new #{size}\n"
          code = "#{inner_indent}e_ =
%s
#{inner_indent}return unless e_
#{inner_indent}r_ << e_
"
          e_indent = inner_indent + '  '
          each do |e|
            r << (code % e.generate(e_indent))
          end

          if wrap
            r << indent << "}[]"
          else
            r
          end
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

    include Nodes
  end
end
