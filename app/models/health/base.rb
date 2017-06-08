module Health
  class Base < HealthBase
    self.abstract_class = true

    def self.source_key= key
      @source_key = key
    end
    def self.source_key 
      @source_key
    end
  end
end
