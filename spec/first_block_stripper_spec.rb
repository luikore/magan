require_relative "spec_helper"

module Magan
  describe FirstBlockStripper do
    it "strips simple block code" do
      res = FirstBlockStripper.new('{hello world}').parse
      assert_equal 'hello world', res
    end
    
    it "strips block code from regular ruby code" do
      inside = '->{/a/}; ->{ ->{} };' * 2
      res = FirstBlockStripper.new("{ #{inside} } | a { -> {} }").parse
      assert_equal inside, res.strip
    end

    it "strips block code from syntax-errored ruby code" do
      inside = '->{/a/}; ->{ ->{} };' * 2
      res = FirstBlockStripper.new("{#{inside}} | a:b").parse
      assert_equal inside, res.strip
    end
    
    it "returns position of syntax error" do
      assert_equal 0, FirstBlockStripper.new("{ 3").parse
      assert_equal 2, FirstBlockStripper.new("{a: 3}; ->{ note }").parse
    end
  end
end
