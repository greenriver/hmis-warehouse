###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Processors::Base
  # DO NOT CHANGE: Frontend code sends this value
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

  def assign_metadata
    @processor.send(factory_name, create: false)&.assign_attributes(
      user: @processor.hud_user,
      data_source_id: @processor.hud_user.data_source_id,
    )
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

  def process_custom_field(field, value)
    record = @processor.send(factory_name)
    return false unless record.respond_to?(:custom_data_elements)

    cded = Hmis::Hud::CustomDataElementDefinition.for_type(record.class.sti_name).find_by(key: field)
    return false unless cded.present?

    attrs = {
      user: @processor.hud_user,
      data_source_id: @processor.hud_user.data_source_id,
      data_element_definition: cded,
    }
    value_field_name = "value_#{cded.field_type}"
    value = attribute_value_for_enum(nil, value) # converts HIDDEN => nil

    existing_values = record.custom_data_elements.where(data_element_definition: cded, owner: record)

    # If this custom field only allows 1 value and there already is one, update it.
    if !cded.repeats && existing_values.exists?
      cde_attributes = { id: existing_values.first.id }
      if value.present?
        cde_attributes[value_field_name] = value
        cde_attributes.merge!(attrs)
      else
        cde_attributes[:_destroy] = 1
      end

      record.assign_attributes(
        custom_data_elements_attributes: [
          # Update or delete the existing value
          cde_attributes,
          # Delete any other values (there shouldn't be any, but just in case)
          *existing_values.drop(1).map { |old_cde| { id: old_cde.id, _destroy: 1 } },
        ],
      )
    # If value(s) haven't changed, just update the User and timestamps
    elsif existing_values.map(&:value) == Array.wrap(value)
      attributes = existing_values.map { |cde| { id: cde.id, user: @processor.hud_user } }
      record.assign_attributes(custom_data_elements_attributes: attributes)
    # Else create new custom field value(s), and delete any existing ones.
    else
      record.assign_attributes(
        custom_data_elements_attributes: [
          # Add new value(s)
          *Array.wrap(value).map { |new_value| { value_field_name => new_value, **attrs } },
          # Destroy any existing values for this custom field
          *existing_values.map { |old_cde| { id: old_cde.id, _destroy: 1 } },
        ],
      )
    end
    true
  end
end
