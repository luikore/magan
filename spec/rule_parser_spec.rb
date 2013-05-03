require_relative "spec_helper"

module Magan
  describe RuleParser do
    it "parses atom" do
      r = parse :atom, '"abc\u0023"'
      assert_equal "abc\x23", r.re

      r = parse :atom, "'abc\\u0023'"
      assert_equal 'abc\u0023', r.re

      r = parse :atom, 'hello'
      assert_equal 'hello', r.id

      r = parse :atom, '\p{Hiragana,Han}'
      assert_equal '[\p{Hiragana}\p{Han}]', r.re

      r = parse :atom, '\p{Hiragana}'
      assert_equal '\p{Hiragana}', r.re

      r = parse :atom, '\k<hello>'
      assert_equal 'hello', r.var
    end

    it "parses seq" do
      r = parse :seq, 'a b+:x $ \k<x>'
      assert_equal unit('a'), r[0]
      assert_equal unit('b', '+', ':x'), r[1]
      assert_equal RuleParser::Re['$'], r[2]
      assert_equal RuleParser::Unit[RuleParser::BackRef['x']], r[3]
    end

    it "parses expr" do
      r = parse :expr, 'a / &"b" / c'
      assert_equal 3, r.branches.size
      assert_equal RuleParser::Pred['&', RuleParser::Re['b'], nil], r.branches[1].first
      assert_equal unit('c'), r.branches[2].first
    end

    it "parses helper" do
      r = parse :helper, 'a[b, c]'
      assert_equal 'a', r.helper
      assert_equal 2, r.args.size
      assert_equal [[unit('b')]], r.args[0].branches
      assert_equal [[unit('c')]], r.args[1].branches
    end

    def parse meth, s
      RuleParser.new(s).send("parse_#{meth}")
    end

    def unit id, qualifier=nil, var=nil
      RuleParser::Unit[RuleParser::Ref[id], qualifier, var]
    end
  end
end
