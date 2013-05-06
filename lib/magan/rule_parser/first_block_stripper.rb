module Magan
  class RuleParser
    class FirstBlockStripper < Ripper::SexpBuilder
      def initialize src
        @src = '->' << src
        @level = 0
        @found = false
        super @src
      end

      def parse
        super
        return 0 if not @found
        lines = @src.lines.to_a
        line = @lineno - 1
        code = (lines[0...line] << lines[line][0...@column]).join[3...-1]

        stripped_code = Ripper.tokenize(code).join
        if stripped_code.size == code.size
          code
        else
          return stripped_code.size
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
end
