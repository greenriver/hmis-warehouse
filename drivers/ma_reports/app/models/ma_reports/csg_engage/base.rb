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

      def field(name, method: nil, subfield: nil, &block)
        method_name = method || (name.is_a?(Symbol) ? name : convert_to_symbol(name))
        fields << {
          method: method_name,
          subfield: subfield || @subfield_name,
          name: name.is_a?(Symbol) ? name.to_s.titleize : name,
        }

        define_method(method_name) { instance_eval(&block) } if block_given?
      end

      def subfield(name, &block)
        @subfield_name = name
        instance_eval(&block)
        @subfield_name = nil
      end

      private

      def convert_to_symbol(string)
        string.underscore.gsub(/\W+/, '_').to_sym
      end
    end

    def serialize
      base_fields = self.class.fields

      {
        **serialize_fields(base_fields.reject { |f| f[:subfield]&.present? }),
        **base_fields.pluck(:subfield).uniq.compact.map do |field|
          [field, serialize_fields(base_fields.select { |f| f[:subfield] == field })]
        end.to_h,
      }
    end

    def serialize_fields(fields_to_use)
      fields_to_use.map do |field|
        value = serialize_value(respond_to?(field[:method]) ? send(field[:method]) : nil)
        next unless value.present?

        [
          field[:name],
          serialize_value(respond_to?(field[:method]) ? send(field[:method]) : nil),
        ]
      end.compact.to_h
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

    def convert_to_symbol(string)
      self.class.convert_to_symbol(string)
    end
  end
end
