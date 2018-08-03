module Health
  class EpicBase < Base
    self.abstract_class = true

    def self.source_key= key
      @source_key = key
    end
    def self.source_key
      @source_key
    end

    # override as necessary
    def self.clean_value key, value
      value
    end

    # override as necessary
    def self.clean_row row:, data_source_id:
      row
    end

  end
end
