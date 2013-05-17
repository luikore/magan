require_relative "spec_helper"

module Magan
  describe Captures do
    before :each do
      @c = Captures.new 3, 3, [0, 2]
    end

    it "#try" do
      node1 = Node.new
      node1.value = 1
      node2 = Node.new
      node2.value = 2
      node3 = Node.new
      node3.value = 3

      @c.acc 0, node1
      @c.try 1, (
        @c.try 2, (
          @c.assign 6 + 1, node1
          nil
        )
        @c.assign 3 + 2, node2
        @c.try 2, (
          @c.acc 6 + 2, node3
          true
        )
        @c.try 2, (
          @c.acc 6 + 0, node3
          nil
        )
        true
      )

      assert_equal [[1], nil, [3]], @c.get
    end
  end
end
