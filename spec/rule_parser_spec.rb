require_relative "spec_helper"

module Magan; module Nodes
  describe RuleParser do

    it "parses atom" do
      r = parse :atom, '"abc\u0023"'
      assert_equal Regexp.escape("abc\x23"), r.re

      r = parse :atom, "'abc\\u0023'"
      assert_equal Regexp.escape('abc\u0023'), r.re

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
      r = parse :seq, 'a x:b+ $ \k<x>'
      assert_equal unit(nil, 'a'), r[0]
      assert_equal unit('x:', 'b', '+'), r[1]
      assert_equal Re['$'], r[2]
      assert_equal Unit[nil, BackRef['x']], r[3]
    end

    it "parses expr" do
      r = parse :expr, 'a / &"b" / c'
      assert_equal 3, r.size
      assert_equal Pred['&', Re['b'], nil], r[1]
      assert_equal unit(nil, 'c'), r[2]
    end

    it "parses helper" do
      r = parse :helper, 'a[b, c]'
      assert_equal 'a', r.helper
      assert_equal 2, r.args.size
      assert_equal unit(nil, 'b'), r.args[0]
      assert_equal unit(nil, 'c'), r.args[1]
    end

    it "parses block" do
      r = parse :block, '{hello world}'
      assert_equal 'hello world', r
    end

    it "parses rules" do
      r = RuleParser.new(%Q{a = x:"hello" { x.reverse }\nb = "world"})
      r.parse
      assert_equal ['a', 'b'], r.rules.keys
      assert_equal 'x.reverse', r.rules['a'].block.strip
    end

    def parse meth, s
      RuleParser.new(s).send("parse_#{meth}")
    end

    def unit var, id, quantifier=nil
      Unit[var, Ref[id], quantifier]
    end
  end
end; end
