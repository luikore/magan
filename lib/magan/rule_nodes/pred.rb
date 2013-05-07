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

      # note: parser ensures that quantifier can never be '?' or '*'
      def generate ct
        if literal?
          ct.add %Q|(@src.match_bytesize(%r"#{to_re}") && [])\n|
          return
        end

        if quantifier
          node_method = Node::QUANTIFIER_MAP[quantifier]
          ct.add "(@src.push; Node.new.#{node_method}(@src){\n"
          ct.push_indent
          atom.generate ct
          ct.pop_indent
          ct.add "}.tap{ @src.pop } && [])\n"
        else
          ct.add "(@src.push;(\n"
          ct.child atom
          ct.add ").tap{ @src.pop } && [])\n"
        end
      end
    end
  end
end
