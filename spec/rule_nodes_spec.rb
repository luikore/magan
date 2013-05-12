require_relative "spec_helper"

module Magan; module RuleNodes
  describe RuleNodes do
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

    it "parses hybrid expr" do
      code = generate Or[
        Seq[
          Ref['a'],
          Unit['x:', Re['b'], '*']
        ],
        Seq[
          Re['b'],
          Unit[nil, Ref['a'], '+']
        ]
      ]

      @src = ZScan.new "baa"
      vars = Vars.new
      assert_equal ['b', ['a', 'a']], eval(code)

      @src = ZScan.new "abb"
      vars = Vars.new
      assert_equal ['a', 'bb'], eval(code)
    end

    it "parses rule" do
      code = generate Rule['hello', Unit['x:', Re['hello'], nil], 'x.reverse', [['x', ':']]]
      @src = ZScan.new 'hello'
      assert_equal 'hello'.reverse, eval(code).value
    end

    def generate node
      ct = CodeGenContext.new ''
      node.generate ct
      ct.join
    end

    # stub for ref invoking
    def parse_a
      @src.scan /a/
    end
  end
end; end
