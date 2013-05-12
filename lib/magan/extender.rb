module Magan
  # module for extend
  module Extender
    attr_reader :rules, :entrance

    def grammar grammar_src
      raise 'need a class' unless is_a?(Class)
      @rules = RuleParser.new(grammar_src).parse
      @generated = {}
      @rules.each do |name, _|
        @generated[name] = false
      end
    end

    def generate_code entrance=:main, trace: false, memoise: false, force: false
      @entrance = entrance.to_s[/(?!\d)\w+/]
      raise "invalid entrance: #{entrance.inspect}, should be a rule name" unless @entrance

      # update only changed ones
      ct = CodeGenContext.new '  '
      @generated.to_a.each do |(name, generated)|
        if force or !generated
          ct.add "def parse_#{name}\n"
          ct.add "  print %Q|#{name}: \#{@src.pos}: |\n" if trace
          ct.child @rules[name]
          ct.add "  .tap{|o| p o}\n" if trace
          ct.add "end\n\n"
          @generated[name] = true if memoise
        end
      end
      ct.join
    end

    def compile entrance=:main
      class_eval generate_code(entrance, memoise: true)
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
