module Magan
  # depth computation (see also code_gen_context.rb)
  #   default = 0
  #   at every try(), depth += 1
  #   max_depth is computed by iterating nodes of or/?/*/+
  #   assign / acc index = depth * vars_size + var_id
  class Captures < Array
    def initialize vars_size, max_depth, acc_var_ids
      super(vars_size * max_depth, nil)
      @vars_size = vars_size
      @acc_var_ids = acc_var_ids
      @assigned = []
    end

    def get
      (0...@vars_size).map do |i|
        e = self[i]
        if @acc_var_ids.include?(i)
          e || []
        else
          e ? e.value : nil
        end
      end
    end

    def assign i, v
      if v
        self[i] = v # (NOTE the node - not nil)
        v
      end
    end

    def acc i, v
      if v
        (self[i] ||= []) << v.value
        v
      end
    end

    # depth from 1
    def try depth, r
      base = depth * @vars_size
      @vars_size.times do |i|
        j = base + i
        if r and self[j]
          prev_j = j - @vars_size
          if @acc_var_ids.include?(i)
            # acc
            if self[prev_j]
              self[prev_j].push *self[j]
            else
              self[prev_j] = self[j]
            end
          else
            # assign (NOTE the node - not nil)
            self[prev_j] = self[j]
          end
        end
        self[j] = nil
      end
      r
    end
  end
end
