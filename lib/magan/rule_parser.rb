module Magan
  class RuleParser
    ID = /(?!\d)\w+/

    STRING = /
      "(?>
        \\\. | # escape
        [^"]   # normal char
      )+"
      |
      '(?>
        \\\\ | # backslash
        \\'  | # single quote
        [^']   # normal char
      )+'
    /x

    ANCHOR = /\^|\$|\\[AzZbB]/

    CHAR_CLASS = /
      \.|\\[nwWdDhHsS] |    # special
      \\p\{\w+(?:,\w+)*\} | # property group
      (?<group> \[\^?(?>\g<group>|\\.|[^\]\\])+\])
    /x

    BACK_REF = /\\k\<(?!\d)\w+\>/x

    QUALIFIER = /[+?*][?*]?/

    PRED_PREFIX = /<?[\&\!]/

    VAR = /::?(?!\d)\w+/

    COMMENT = /\#.*$/

    <<-RUBY
    rules     = join[rule, \s* "\n" \s*]
    rule      = id _ '=' _ expr _ block?
    expr      = join[seq, _ '/' _]
    seq       = join[anchor / pred / unit, _]
    pred      = pred_prefix _ atom _ qualifier?
    unit      = atom _ qualifier? _ var?
    atom      = paren / helper / id / string / char_class / back_ref
    paren     = '(' _ expr _ ')'
    expr_list = join[expr, _ "," _]
    helper    = id '[' _ expr_list _ ']'
    RUBY

    def initialize src
      @src = StringScanner.new src.strip
    end
    attr_reader :rules

    def parse
      @rules = {}
      unless parse_rules
        raise 'expect a rule'
      end
      unless @src.eos?
        raise 'syntax error'
      end
    end

    def parse_rules
      join :parse_rule do
        @src.scan /\s*\n\s*/
      end
    end

    def parse_rule
      id = @src.scan ID
      return unless id
      skip_space
      return unless @src.scan(/=/)
      skip_space
      expr = parse_expr
      return unless expr
      skip_space
      block = maybe{ parse_block }

      if @rules[id]
        raise "redefinition of rule: #{id}"
      end
      rule = Rule[id, expr, block]
      rules[id] = rule
      rule
    end

    def parse_expr
      res = join :parse_seq do
        skip_space
        match = @src.scan /\//
        skip_space
        match
      end

      if res
        Or[res]
      else
        false
      end
    end

    def parse_seq
      join :parse_seq_arg1 do
        skip_space
        true
      end
    end

    def parse_seq_arg1
      anchor = @src.scan ANCHOR
      if anchor
        return Re[anchor]
      end

      pos = @src.pos
      if pred = parse_pred
        return pred
      end
      @src.pos = pos

      parse_unit
    end

    def parse_pred
      prefix = @src.scan PRED_PREFIX
      if prefix
        skip_space
        atom = parse_atom
        unless atom
          return false
        end
        skip_space
        qualifier = maybe{ @src.scan QUALIFIER }
        Pred[prefix, atom, qualifier]
      end
    end

    def parse_unit
      atom = parse_atom
      return unless atom
      skip_space
      qualifier = maybe{ @src.scan QUALIFIER }
      skip_space
      var = maybe{ @src.scan VAR }
      Unit[atom, qualifier, var]
    end

    def parse_atom
      pos = @src.pos

      if expr = parse_paren
        return expr
      end
      @src.pos = pos

      if helper = parse_helper
        return helper
      end
      @src.pos = pos

      if id = (@src.scan ID)
        return Ref[id]
      end

      if string = (@src.scan STRING)
        return Re[YAML.load(string)]
      end

      if char_class = (@src.scan CHAR_CLASS)
        char_class.gsub!(/\.|\\p\{\w+(?:,\w+)+\}/){|s|
          if s.size == 2
            s
          elsif s.index(',')
            # \p{S,P} => \p{S}\p{P}
            '[' << s.gsub(',', '}\\p{') << ']'
          else
            s
          end
        }
        return Re[char_class]
      end

      if back_ref = (@src.scan BACK_REF)
        return BackRef[back_ref[/(?<=\<)\w+/]]
      end
    end

    def parse_paren
      return unless @src.scan /\(/
      skip_space
      return unless expr = parse_expr
      skip_space
      return unless @src.scan /\)/
      expr
    end

    def parse_expr_list
      join :parse_expr do
        skip_space
        match = @src.scan /,/
        skip_space
        match
      end
    end

    def parse_helper
      id = @src.scan ID
      return unless id
      return unless @src.scan /\[/
      expr_list = parse_expr_list
      return unless expr_list
      return unless @src.scan /\]/
      Helper[id, expr_list]
    end

    def parse_block
      return unless @src.match?(/\{/)
      s = @src.string[@src.pos..-1]
      res = FirstBlockStripper.new(s).parse
      if res.is_a?(String)
        res
      else
        @src.pos += res
        false
      end
    end

    private

    def maybe
      pos = @src.pos
      res = yield
      if res
        res
      else
        @src.pos = pos
        nil
      end
    end

    # join(arg1){ arg2 }
    def join arg1
      res = send arg1
      return unless res
      arr = [res]

      loop do
        pos = @src.pos
        unless yield
          @src.pos = pos
          break
        end
        res = send arg1
        if res
          arr << res
        else
          @src.pos = pos
          break
        end
      end

      arr
    end

    def skip_space
      until @src.scan(/\s*(\#.*$\s*)*/).empty?
      end
    end
  end
end
