module Magan
  class Captures < Array
    # create init_hash string
    def self.init_add_values_s vars
      a = []
      vars.each do |v|
        if v.end_with?('::')
          a << %Q|:#{v[0...-2]} => []|
        end
      end
      a.join ', '
    end

    def initialize init_hash={}
      super()
      push init_hash
    end

    def assign name, v
      if v
        last[name] = v.value
        v
      end
    end

    def add name, v
      if v
        (last[name] ||= []) << v.value
        v
      end
    end

    def push_hash hash={}
      push hash
      self
    end

    def try r
      hash = pop
      if r
        # merge values
        l = last
        hash.each do |k, v|
          if v.is_a?(Array)
            l[k].push *v
          else
            l[k] = v
          end
        end
      end
      r
    end
  end
end
