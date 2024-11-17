# wrap a PII field for scrubbing
module GrdaWarehouse::Tasks::ScrubPii
  class PiiAttribute
    attr_accessor :name, :type

    def self.from_record(record)
      record.class.pii_attributes_config.values.map do |attribute, type, required|
        new(attribute, type, required, record)
      end
    end

    def initialize(name, type, required, record)
      self.name = name
      self.type = type
      @required = required
      @record = record
    end

    def required?
      !!@required
    end

    def scrub(value)
      return if @scrubbed

      @scrubbed = true
      @scrubbed_value = value
    end

    def scrubbed_value
      raise "PII in #{record.class.name}[#{record.id}]##{name} was not scrubbed" unless @scrubbed

      @scrubbed_value
    end

    def real_value
      @record.send(name)
    end

    def record_id
      @record.id
    end
  end
end
