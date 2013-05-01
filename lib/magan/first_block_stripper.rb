module Magan
  class FirstBlockStripper < Ripper::SexpBuilder
    def initialize src
      @src = '->' + src.strip
      @level = 0
      @found = false
      super @src
    end

    def parse
      super
      raise 'not found' if not @found
      lines = @src.lines.to_a
      line = @lineno - 1
      (lines[0...line] << lines[line][0...@column]).join[3...-1]
    end

    # token "->", order: left to right
    def on_tlambda *xs
      unless @found
        @level += 1
      end
      super
    end

    # order: inside to outside
    def on_lambda *xs
      unless @found
        @level -= 1
        if @level == 0
          @found = true
          @lineno = lineno
          @column = column
        end
      end
      super
    end
  end
end
