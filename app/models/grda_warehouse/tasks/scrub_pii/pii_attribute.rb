module GrdaWarehouse::Tasks::ScrubPii
  class PiiAttribute
    attr_accessor :type, :type, :record, :scrubbed_value

    def self.from_record(record)
      record.class.pii_attributes_config.map do |attribute, type|
        new(attribute, type, self)
      end
    end

    def initialize(name, type, record)
      self.name = name
      self.type = name
      self.record= name
    end

    def scrubbed?
      !!@scrubbed
    end

    def scrub(value)
      return if @scrubbed?

      @scrubbed = true
      scrubbed_value = value
    end

    def raw_value
      record.send(name)
    end
  end
end
