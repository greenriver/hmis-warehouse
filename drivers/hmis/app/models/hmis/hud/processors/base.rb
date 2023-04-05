###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Processors::Base
  HIDDEN_FIELD_VALUE = '_HIDDEN'.freeze

  def initialize(processor)
    @processor = processor
    @hud_values = processor.custom_form.hud_values
  end

  def process(field, value)
    attribute_name = hud_name(field)
    attribute_value = attribute_value_for_enum(hud_type(field), value)

    @processor.send(factory_name).assign_attributes(attribute_name => attribute_value)
  end

  def information_date(date)
    @processor.send(factory_name, create: false)&.assign_attributes(information_date: date)
  end

  def hud_name(field)
    field.underscore
  end

  def self.hud_type(field, schema)
    return nil unless schema.fields[field].present?

    type = schema.fields[field].type
    (type = type&.of_type) while type.non_null? || type.list?
    return nil unless type.respond_to?(:value_for)

    type
  end

  def hud_type(field)
    self.class.hud_type(field, schema)
  end

  def attribute_value_for_enum(enum_type, value)
    is_array = value.is_a? Array

    # The field was left empty. Save as nil or 99.
    if value.nil?
      enum_type&.data_not_collected_value
    elsif is_array && value.empty?
      [enum_type&.data_not_collected_value].compact
    # The field was hidden. Always save as nil.
    elsif value == HIDDEN_FIELD_VALUE
      nil
    # Use the HUD enumeration value, or if the HUD type doesn't have a translator, fall back to the DB one
    elsif is_array
      value.map { |val| enum_type&.value_for(val) || val }
    else
      enum_type&.value_for(value) || value
    end
  end

  # @return [Symbol] the name of the instance factory method on the processor
  def factory_name
    raise 'Implement in sub-class'
  end

  # The GraphQL schema for the HMIS type to translate string values into DB values,
  # or nil to use the DB translation.
  #
  # @return [Class, nil] a schema class that implements respond_to?, or nil
  def schema
    raise 'Implement in sub-class'
  end
end
