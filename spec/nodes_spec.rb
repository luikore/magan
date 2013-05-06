require_relative "spec_helper"

module Magan; module RuleNodes
  describe RuleNodes do
    def generate node
      ct = CodeGenerateContext.new ''
      node.generate ct
      ct.join
    end

    it "parses ref unit" do
      unit = generate Unit[nil, Ref['a'], '*']
      @src = ZScan.new 'aa'
      assert_equal ['a', 'a'], eval(unit)
      @src = ZScan.new ''
      assert_equal [], eval(unit)
    end

    it "parses literal unit" do
      unit = generate Unit[nil, Or[Re['a'], Re['b']], '+']
      @src = ZScan.new 'abac'
      assert_equal 'aba', eval(unit)
      @src = ZScan.new 'c'
      assert_equal nil, eval(unit)
    end

    it "parses ref predicate" do
      pred = generate Pred['&', Ref['a'], nil]
      @src = ZScan.new 'a'
      assert_equal [], eval(pred)
      @src = ZScan.new ''
      assert_equal nil, eval(pred)
    end

    it "parses literal predicate" do
      pred = generate Pred['<&', Re['b'], nil]
      @src = ZScan.new 'bc'
      assert_equal nil, eval(pred)
      @src.pos = 1
      assert_equal [], eval(pred)
    end

    it "parses hybrid rule_nodes" do
      or1 = Or.new
      seq1 = Seq.new
      seq1 << Ref['a'] << Unit['x:', Re['b'], '*']
      seq2 = Seq.new
      seq2 << Re['b'] << Unit[nil, Ref['a'], '+']
      or1 << seq1 << seq2
      code = generate or1

      @src = ZScan.new "baa"
      assert_equal ['b', ['a', 'a']], eval(code)
      @src = ZScan.new "abb"
      assert_equal ['a', ['b', 'b']], eval(code)
    end

    # stub for ref invoking
    def parse_a
      @src.scan /a/
    end
  end
end; end
