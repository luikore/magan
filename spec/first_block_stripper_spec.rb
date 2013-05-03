require_relative "spec_helper"

module Magan
  describe FirstBlockStripper do
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

    it "won't strip block code when there's syntax error" do
      assert_raise FirstBlockStripper::SyntaxError do
        FirstBlockStripper.new("{ 3").parse
      end
      assert_raise FirstBlockStripper::SyntaxError do
        FirstBlockStripper.new("{a: 3}; ->{ note }").parse
      end
    end
  end
end
