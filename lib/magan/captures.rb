module Magan
  # depth computation (see also rule_nodes.rb)
  #   default = 0
  #   before every try(), depth += 1
  #   after try(), depth -= 1
  #   max_depth is computed by iterating nodes of or/?/*/+
  #
  # var_id used in assign / acc:
  #   depth * vars_size + var_id
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
          e ? e.map!(&:value) : []
        else
          e ? e.value : nil
        end
      end
    end

    def assign i, node
      if node
        self[i] = node
        node
      end
    end

    def acc i, node
      if node
        (self[i] ||= []) << node
        node
      end
    end

    # depth from 1
    def try depth, r
      base = depth * @vars_size
      @vars_size.times do |i|
        j = base + i
        if r and self[j]
          prev_j = j - @vars_size
          if @acc_var_ids.include?(i) and self[prev_j]
            # acc
            self[prev_j].push *self[j]
          else
            # prev acc == nil or assign
            self[prev_j] = self[j]
          end
        end
        self[j] = nil
      end
      r
    end
  end
end
