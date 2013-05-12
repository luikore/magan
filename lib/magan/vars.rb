module Magan
  class Vars < Hash
    def assign name, v
      if v
        self[name] = v.value
        v
      end
    end

    def add name, v
      if v
        self[name] << v.value
        v
      end
    end
  end
end
