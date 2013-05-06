module Magan
  module RuleNodes
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

      def vars
        atom.vars
      end

      WRAP_OPEN   = "lambda{|;r_, e_|\n"
      WRAP_CLOSE  = "}[]\n"
      STACK_OPEN  = "@src.push\n"
      STACK_CLOSE = <<RUBY.lines
if r_
  @src.pop
  []
else
  @src.drop
  nil
end
RUBY

      # note: parser ensures that quantifier can never be '?' or '*'
      def generate ct, wrap=true
        if literal?
          ct.add %Q|(@src.match_bytesize(%r"#{to_re}") ? [] : nil)\n|
          return
        end

        if wrap
          ct.add WRAP_OPEN
          ct.push_indent
        end

        ct.add STACK_OPEN
        Unit[nil, atom, quantifier].generate ct, false
        STACK_CLOSE.each{|line| ct.add line }
        if wrap
          ct.pop_indent
          ct.add WRAP_CLOSE
        end
      end
    end
  end
end
