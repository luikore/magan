module Magan
  class FirstBlockStripper < Ripper::SexpBuilder
    class SyntaxError < Exception
      def initialize pos
        @pos = pos
      end
      attr_reader :pos
    end

    def initialize src
      @src = '->' + src.strip
      @level = 0
      @found = false
      super @src
    end

    def parse
      super
      raise SyntaxError.new(0) if not @found
      lines = @src.lines.to_a
      line = @lineno - 1
      code = (lines[0...line] << lines[line][0...@column]).join[3...-1]

      stripped_code = Ripper.tokenize(code).join
      if stripped_code.size == code.size
        code
      else
        raise SyntaxError.new(stripped_code.size)
      end
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
