module Magan
  # module for extend
  module Ext
    attr_reader :rules, :entrance

    def grammar grammar_src
      raise 'need a class' unless is_a?(Class)
      @rules = RuleParser.new(grammar_src).parse
      @generated = {}
      @rules.each do |name, _|
        @generated[name] = false
      end
    end

    def compile entrance=:main
      @entrance = entrance.to_s[/(?!\d)\w+/]
      raise "invalid entrance: #{entrance.inspect}, should be a rule name" unless @entrance

      # update only changed ones
      ctx = CodeGenContext.new '  '
      @generated.to_a.each do |(name, generated)|
        unless generated
          ctx.add "def parse_#{name}\n"
          ctx.child @rules[name]
          ctx.add "end\n\n"
          @generated[name] = true
        end
      end
      code = ctx.join
      class_eval code
    end

    def helper
      @helper ||= {}
    end

    def closure rule

    end

    def parse src
      parser = new src
      r = parser.send "parse_#@entrance"
      if r and parser.src.eos?
        r
      else
        raise "syntax error at: #{parser.src.pos}"
      end
    end
  end
end
