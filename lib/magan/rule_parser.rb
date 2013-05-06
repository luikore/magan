module Magan
  class RuleParser
    RULE_ID = /(?!\d)\w+/

    ID = /(?!\d)(?>\w+)(?!\s*=)/

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

    QUANTIFIER = /[+?*][?*]?/

    PRED_PREFIX = /<?[\&\!]/

    VAR = /(?!\d)\w+::?/

    COMMENT = /\#.*$/

    <<-RUBY
    rules     = join[rule, \s* "\n" \s*]
    rule      = id _ '=' _ expr (_ block)?
    expr      = join[seq, _ '/' _]
    seq       = join[anchor / pred / unit, _]
    pred      = pred_prefix _ atom (_ quantifier)?
    unit      = var? _ atom _ quantifier?
    atom      = paren / helper / id / string / char_class / back_ref
    paren     = '(' _ expr _ ')'
    expr_list = join[expr, _ "," _]
    helper    = id '[' _ expr_list _ ']'
    RUBY

    def initialize src
      @src = ZScan.new src.strip
    end
    attr_reader :rules

    def parse
      @rules = {}
      unless parse_rules
        raise SyntaxError, "expect a rule at #{@src.pos}"
      end
      unless @src.eos?
        puts (@src.string[0...(@src.pos)].inspect + ' <|> ' + @src.rest.inspect)
        puts ''
        raise SyntaxError, "syntax error at #{@src.pos}"
      end
      @rules
    end

    def parse_rules
      join :parse_rule do
        @src.scan /\s*\n\s*/
      end
    end

    def parse_rule
      id = @src.scan RULE_ID
      return unless id
      skip_space
      return unless @src.scan(/=/)
      skip_space
      expr = parse_expr
      return unless expr
      block = maybe{
        skip_space
        parse_block
      }

      if @rules[id]
        raise "redefinition of rule: #{id}"
      end
      rule = Rule[id, expr, block]
      rules[id] = rule
      rule
    end

    def parse_expr
      r = Or.new
      join :parse_seq, r do
        skip_space
        match = @src.scan /\//
        skip_space
        match
      end
      if r.size == 1
        r.first
      else
        r
      end
    end

    def parse_seq
      r = Seq.new
      join :parse_seq_arg1, r do
        skip_space
        true
      end
      if r.size == 1
        r.first
      else
        r
      end
    end

    def parse_seq_arg1
      anchor = @src.scan ANCHOR
      if anchor
        return Re[anchor]
      end

      @src.push
      if pred = parse_pred
        @src.drop
        return pred
      end
      @src.pop

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
        case (quantifier = maybe{ @src.scan QUANTIFIER })
        when /^[\?\*]/
          case prefix
          when '&', '<&'
            Success[] # always match
          else
            Fail[] # always not match
          end
        else
          Pred[prefix, atom, quantifier]
        end
      end
    end

    def parse_unit
      var = maybe{ @src.scan VAR }
      skip_space
      atom = parse_atom
      return unless atom
      quantifier = maybe{
        skip_space
        @src.scan QUANTIFIER
      }
      Unit[var, atom, quantifier]
    end

    def parse_atom
      @src.push

      if expr = parse_paren
        @src.drop
        return expr
      end
      @src.restore

      if helper = parse_helper
        @src.drop
        return helper
      end
      @src.pop

      if id = (@src.scan ID)
        return Ref[id]
      end

      if string = (@src.scan STRING)
        return Re[Regexp.escape(YAML.load string)]
      end

      if char_class = (@src.scan CHAR_CLASS)
        char_class.gsub!(/\.|\\p\{\w+(?:,\w+)+\}/){|s|
          if s.size == 2
            s
          elsif s.index(',')
            # \p{S,P} => [\p{S}\p{P}]
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
      return unless @src.match_bytesize(/\{/)
      s = @src.string[@src.pos..-1]
      res = FirstBlockStripper.new(s).parse
      if res.is_a?(String)
        @src.pos += res.size + 2
        res
      else
        @src.pos += res
        false
      end
    end

    private

    def maybe
      @src.push
      res = yield
      if res
        @src.drop
        res
      else
        @src.pop
        nil
      end
    end

    # join(arg1, arr){ arg2 }
    def join arg1, arr=[]
      res = send arg1
      return unless res
      arr << res

      loop do
        @src.push
        unless yield
          @src.pop
          break
        end
        res = send arg1
        if res
          @src.drop
          arr << res
        else
          @src.pop
          break
        end
      end

      arr
    end

    def skip_space
      @src.skip(/\s*(\#.*$\s*)*/)
    end
  end
end
