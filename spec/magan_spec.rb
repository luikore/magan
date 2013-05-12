require_relative "spec_helper"

module Magan
  describe Magan do
    it "detects ambiguous var type" do
      p = RuleParser.new %Q{a = x:"a" x::"b"}
      p.parse
      rule = p.rules['a']
      ct = CodeGenContext.new ''
      assert_raise RuleParser::DefinitionError do
        rule.generate ct
      end
    end

    it "detects recurrence aggregate var" do
      p = RuleParser.new %Q{a = x::"a" x::"b"}
      p.parse
      rule = p.rules['a']
      ct = CodeGenContext.new ''
      assert_raise RuleParser::DefinitionError do
        rule.generate ct
      end
    end

    it "evals arithmetic" do
      class Arithmetic
        include Magan
        grammar %q<
          expr = _ v:add _ { v }
          int  = '-'? \d+  { ast.value.to_i }
          atom = '(' _ v:expr _ ')' / v:int { v }
          mul  = x:atom (_ ops::[*/] _ xs::atom)* { calculate x, ops, xs }
          add  = x:mul  (_ ops::[+-] _ xs::mul)*  { calculate x, ops, xs }
          _    = [\ \t]*
        >
        # puts nl generate_code :expr
        compile :expr

        def calculate x, ops, xs
          ops.zip(xs).inject(x){|r, (op, rhs)| r.send op, rhs }
        end
      end

      src = '3 + -2 * 9'
      assert_equal eval(src), Arithmetic.parse(src).value
    end
  end
end
