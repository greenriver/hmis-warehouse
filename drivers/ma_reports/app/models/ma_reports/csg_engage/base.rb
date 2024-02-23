###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Base
    class << self
      attr_writer :fields

      def fields
        @fields ||= []
      end

      def field(name, label: nil, &block)
        fields << { method: name, label: label.present? ? label : name.to_s.titleize }

        define_method(name) { instance_eval(&block) } if block_given?
      end
    end

    def serialize
      self.class.fields.map do |field|
        puts field[:label]
        [
          field[:label],
          serialize_value(send(field[:method])),
        ]
      end.to_h
    end

    def serialize_value(value)
      value = value.serialize if value.is_a?(MaReports::CsgEngage::Base)
      value = value.map { |v| serialize_value(v) } if value.is_a?(Array)
      value
    end

    def boolean_string(value, allow_unknown: false)
      return 'Y' if value == true
      return 'N' if value == false

      allow_unknown ? 'U' : 'N'
    end

    private

    def households_scope
      project.enrollments.heads_of_households
    end
  end
end
