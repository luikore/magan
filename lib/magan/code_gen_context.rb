module Magan
  class CodeGenContext < Array
    def initialize indent
      @indent = indent
      @indents = [@indent]
      @seqs = []
      @seq_i = 0
      super()
    end
    attr_reader :indent

    def push_indent
      @indents.push @indent
      @indent += '  '
    end

    def pop_indent
      @indent = @indents.pop
    end

    def add line
      # raise "bad line" unless line.end_with?("\n")
      self << @indent << line
    end

    def child node
      push_indent
      node.generate self
      pop_indent
    end

    # allocate a name of seq
    def alloc
      if @seqs.empty?
        @seq_i += 1
        "seq#{@seq_i}_"
      else
        @seqs.pop
      end
    end

    # free a name of seq
    def free a
      @seqs << a
    end
  end
end
