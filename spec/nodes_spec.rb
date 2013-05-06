require_relative "spec_helper"

module Magan; module Nodes
  describe Nodes do
    it "parses ref unit" do
      unit = Unit[nil, Ref['a'], '*'].generate ''
      @src = ZScan.new 'aa'
      assert_equal ['a', 'a'], eval(unit)
      @src = ZScan.new ''
      assert_equal [], eval(unit)
    end

    it "parses literal unit" do
      unit = Unit[nil, Or[Re['a'], Re['b']], '+'].generate ''
      @src = ZScan.new 'abac'
      assert_equal 'aba', eval(unit)
      @src = ZScan.new 'c'
      assert_equal nil, eval(unit)
    end

    it "parses ref predicate" do
      pred = Pred['&', Ref['a'], nil].generate ''
      @src = ZScan.new 'a'
      assert_equal [], eval(pred)
      @src = ZScan.new ''
      assert_equal nil, eval(pred)
    end

    it "parses literal predicate" do
      pred = Pred['<&', Re['b'], nil].generate ''
      @src = ZScan.new 'bc'
      assert_equal nil, eval(pred)
      @src.pos = 1
      assert_equal [], eval(pred)
    end

    it "parses hybrid nodes" do
      or1 = Or.new
      seq1 = Seq.new
      seq1 << Ref['a'] << Unit['x:', Re['b'], '*']
      seq2 = Seq.new
      seq2 << Re['b'] << Unit[nil, Ref['a'], '+']
      or1 << seq1 << seq2
      code = or1.generate('  ')

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
