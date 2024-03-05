###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ExitProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      attributes = case attribute_name
      when 'aftercare_methods'
        multi_select_attributes(value, attribute_value, enum_map: HudUtility2024.aftercare_method_fields)
      when 'counseling_methods'
        multi_select_attributes(value, attribute_value, enum_map: HudUtility2024.counseling_method_fields)
      else
        { attribute_name => attribute_value }
      end
      @processor.send(factory_name).assign_attributes(attributes)
    end

    def factory_name
      :exit_factory
    end

    def relation_name
      :exit
    end

    def schema
      Types::HmisSchema::Exit
    end

    def information_date(_)
      # Exits don't have an information date to be set
    end

    def multi_select_attributes(raw_value, attribute_value, enum_map:)
      # If hidden, set all fields to nil
      return enum_map.transform_values { |_| nil } if raw_value == Base::HIDDEN_FIELD_VALUE

      # If all empty, set all fields to 99
      values = Array.wrap(attribute_value).compact
      return enum_map.transform_values { |_| 99 } if values.empty?

      enum_map.map do |field_name, id|
        [field_name, values.include?(id) ? 1 : 0]
      end.to_h
    end
  end
end
