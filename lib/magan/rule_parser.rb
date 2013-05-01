module Magan
  RuleParser = Struct.new :src, :start_line
  class RuleParser
    ID = /(?!\d)\w+/

    DOUBLE_S = /
      "(?>
        \\\. | # escape
        [^"]   # normal char
      )+"
    /x

    SINGLE_S = /'(?>
      \\\\ | # backslash
      \\'  | # single quote
      [^']   # normal char
    )+'/x

    ANCHOR = /\^|\$|\\[AzZbB]/

    CHAR_CLASS = /
      (?<unicode_class> \\p\{\w+(,\w+)*\}  ){0}
      (?<special_class> \.|\\[nwWdDhHsS]   ){0}
      (?<group>         \[\^?(?>\g<group>|\\.|[^\]\\])+\] ){0}
      \g<special_class> | \g<unicode_class> | \g<group>
    /x

    BACK_REF = /\\k\<(?!\d)\w+\>/x

    QUALIFIER = /\+\?|\*\?|[\+\*\?]/

    PRED_PREFIX = /<?[\&\!]/

    SPACE = /\s*/

    VAR = /::?(?!\d)\w+/

=begin
    rules     = join[rule, _ "\n" _]
    rule      = id _ '=' _ expr _ block?
    expr      = join[seq, _ '/' _]
    seq       = join[anchor / pred / atom qualifier? var?, _]
    pred      = pred_prefix _ atom
    atom      = ('(' _ expr _ ')' / helper / id / single_s / double_s / char_class / back_ref) qualifier?
    expr_list = join[expr, _ "," _]
    helper    = id '[' _ expr_list _ ']'
=end
    def parse
      parse_expr
      # Rule.new branches
    end

    def parse_function
      name = @src.scan /(?!\d)\w+\[/
      return unless name

      name = name[0...-1]
      args = parse_seq.tokens
      raise "paren not closed" unless @src.scan(/\]/)
      Function[name, args]
    end

    def parse_expr

    end

    def parse_seq
      tokens
    end

    def parse_token
      pos = @src.pos
      @src.skip SPACE
      predicate_prefix = @src.scan PREDICATE_PREFIX
      @src.skip SPACE
      if @src.eos?
        return
      end

      token = (@src.scan(REF) or @src.scan(SINGLE_QUOTED_STRING) or @src.scan(DOUBLE_QUOTED_STRING) or @src.scan(REGEXP))
      unless token
        @src.pos = pos
        raise "failed to parse token at: #{@src.pos}"
      end

      @src.skip SPACE
      qualifier_suffix = @src.scan QUALIFIER_SUFFIX
      Token[predicate_prefix, token, qualifier_suffix]
    end

    def parse_block

    end
  end
end
