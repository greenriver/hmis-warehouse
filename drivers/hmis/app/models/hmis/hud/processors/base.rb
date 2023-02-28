###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Processors::Base
  HIDDEN_FIELD_VALUE = '_HIDDEN'.freeze

  def initialize(processor)
    @processor = processor
    @hud_values = processor.assessment_detail.hud_values
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

  def hud_type(field)
    type = schema.fields[field].type
    return nil unless type.respond_to?(:value_for)

    type
  end

  def attribute_value_for_enum(enum_type, value)
    if value.nil?
      # The field was left empty. Save as nil or 99.
      enum_type&.data_not_collected_value
    elsif value == HIDDEN_FIELD_VALUE
      # The field was hidden. Always save as nil.
      nil
    else
      # Use the HUD enumeration value, or if the HUD type doesn't have a translator, fall back to the DB one
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
