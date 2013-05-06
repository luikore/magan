module Magan
  module Nodes
    class Or < ::Array
      def self.[] *xs
        r = new
        xs.each do |x|
          r << x
        end
        r
      end

      def literal?
        return @literal unless @literal.nil?
        @literal = all?(&:literal?)
      end

      def to_re
        map(&:to_re).join '|'
      end

      def vars
        flat_map &:vars
      end

      WRAP_OPEN = "lambda {|;r_|\n"
      WRAP_CLOSE = "}[]\n"
      STACK_OPEN = "@src.push\n"
      STACK_CLOSE = "@src.drop\nr_\n".lines

      def generate ct, wrap=true
        if literal?
          ct.add %Q|@src.scan(%r"#{to_re}")\n|
          return
        end

        if wrap
          ct.add WRAP_OPEN
          ct.push_indent
        end

        ct.add STACK_OPEN
        before = "#{ct.indent}r_ =\n"
        after = "#{ct.indent}if r_
#{ct.indent}  @src.drop
#{ct.indent}  return r_
#{ct.indent}else
#{ct.indent}  @src.restore
#{ct.indent}end
"
        ct.push_indent
        *es, last = self
        es.each do |e|
          ct << before
          e.generate ct
          ct << after
        end
        ct.pop_indent
        last.generate ct, false

        STACK_CLOSE.each{|line| ct.add line }

        if wrap
          ct.pop_indent
          ct.add WRAP_CLOSE
        end
      end
    end
  end
end
