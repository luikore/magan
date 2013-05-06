require_relative "spec_helper"

describe Magan do
  it "parses" do
    src = '3 + -2 * 9'
    assert_equal src, ExampleGrammar.parse(src).join
  end
end
