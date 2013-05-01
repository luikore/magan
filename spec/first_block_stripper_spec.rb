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
  end
end
