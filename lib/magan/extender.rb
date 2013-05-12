module Magan
  # module for extend
  module Extender
    attr_reader :rules, :entrance

    def grammar grammar_src, file='grammar', start_line=0
      raise 'need a class' unless is_a?(Class)
      @rules = RuleParser.new(grammar_src).parse
      @generated = {}
      @rules.each do |name, _|
        @generated[name] = false
      end
      @file = file
      @start_line = start_line
    end

    def generate_code entrance=:main, trace: false, incremental: false
      @entrance = entrance.to_s[/(?!\d)\w+/]
      raise "invalid entrance: #{entrance.inspect}, should be a rule name" unless @entrance

      ct = CodeGenContext.new '  '
      @generated.to_a.each do |(name, generated)|
        if !(incremental and generated)
          rule = @rules[name]
          ct.add "# file: #{@file}, line: #{@start_line + rule.line_index + 1}\n"
          rule.generate_parse ct, trace
          if incremental
            @generated[name] = true
          elsif rule.block
            if rule.block_line_index
              ct.add "# file: #{@file}, line: #{@start_line + rule.block_line_index + 1}\n"
            end
            rule.generate_exec ct
          end
        end
      end

      ct.join
    end

    def compile entrance=:main
      class_eval generate_code(entrance, incremental: true)
      @rules.each do |name, rule|
        if rule.block.is_a?(String)
          class_eval rule.generate_exec(nil), @file, @start_line + rule.block_line_index
        elsif rule.block.respond_to?(:call)
          define_method name, rule.block
        end
      end
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
