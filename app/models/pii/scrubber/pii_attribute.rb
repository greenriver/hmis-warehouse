# wrap a PII field for scrubbing
module Pii::Scrubber
  class PiiAttribute
    attr_reader :name, :type, :level, :record

    def self.from_record(record)
      record.class.pii_attributes_config.values.map do |config|
        new(**config, record: record)
      end
    end

    def initialize(name:, type:, required:, level:, record:)
      @name = name
      @type = type
      @level = level
      @required = required
      @record = record
    end

    def description
      "#{record.class.name}##{name} (#{type})"
    end

    def required?
      !!@required
    end

    def sensitive?
      level < 3
    end

    def scrubbed?
      !!@scrubbed
    end

    def scrub(value)
      @scrubbed = true
      @scrubbed_value = value
    end

    def scrubbed_value
      raise "PII in #{record.class.name}[#{record.id}]##{name} was not scrubbed" unless @scrubbed

      @scrubbed_value
    end

    def real_value
      record.send(name)
    end

    def record_id
      record.id
    end
  end
end
