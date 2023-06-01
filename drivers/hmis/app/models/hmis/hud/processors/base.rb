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
    attribute_name = ar_attribute_name(field)
    attribute_value = attribute_value_for_enum(graphql_enum(field), value)

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

  def ar_attribute_name(field)
    field.underscore
  end

  # Get the GraphQL Type class for this field
  def self.graphql_type(field, schema)
    return nil unless schema.present?
    return nil unless schema.fields[field].present?

    type = schema.fields[field].type
    (type = type&.of_type) while type.non_null? || type.list?
    type
  end

  # Get the GraphQL Enum class for this field (if any)
  def self.graphql_enum(field, schema)
    type = graphql_type(field, schema)
    # return nil if it's not an Enum
    return nil unless type.respond_to?(:value_for)

    type
  end

  def graphql_type(field)
    self.class.graphql_type(field, schema)
  end

  def graphql_enum(field)
    self.class.graphql_enum(field, schema)
  end

  # Transform the received value into the value that should be stored in the database
  # For example:
  #     'CLIENT_REFUSED' => 9
  #     ['PH', 'ES'] => [10, 1]
  #     nil => 99
  #     _HIDDEN => nil
  #     'some value' => 'some value'
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

  # Assign custom data element values to record, if this is a custom data element field
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
    # If value(s) haven't changed, just update the User and timestamps
    elsif existing_values.map(&:value) == Array.wrap(value)
      cde_attributes = existing_values.map { |cde| { id: cde.id, user: @processor.hud_user } }
    # Else create new custom field value(s), and delete any existing ones.
    else
      cde_attributes = [
        # Add new value(s)
        *Array.wrap(value).map { |new_value| { value_field_name => new_value, **attrs } },
        # Destroy any existing values for this custom field
        *existing_values.map { |old_cde| { id: old_cde.id, _destroy: 1 } },
      ]
    end

    record.assign_attributes(custom_data_elements_attributes: Array.wrap(cde_attributes))
    true
  end

  # Get attributes for nested record(s)
  def construct_nested_attributes(field, value, additional_attributes: {}, scope_name: nil)
    values = Array.wrap(value)

    object_type = graphql_type(field) # eg the ClientName type
    raise "'#{field}' not found in gql schema" unless object_type.present?

    # Construct attribute objects for creating/updating records
    attributes = values.map do |attribute_hash|
      raise "Error constructing nested attributes: expected Hash, found #{attribute_hash.class.name}" unless attribute_hash.is_a?(Hash)

      transformed = attribute_hash.map do |field_name, field_value|
        # transform "nameDataQuality"=>"FULL_NAME_REPORTED" to "name_data_quality"=>1
        transformed_value = attribute_value_for_enum(self.class.graphql_enum(field_name, object_type), field_value)
        [ar_attribute_name(field_name)&.to_sym, transformed_value]
      end.to_h

      { **transformed, **additional_attributes }
    end

    # Add directive to destroy any records that aren't present in values
    attribute_name = ar_attribute_name(field)
    existing_values = @processor.send(factory_name).send(attribute_name)
    existing_values = existing_values.send(scope_name) if scope_name.present?
    existing_values_ids = existing_values.pluck(:id)
    seen_ids = []
    attributes.each do |attrs|
      id = attrs[:id]&.to_i
      next unless id.present?

      if existing_values_ids.include?(id)
        seen_ids << id
      else
        attrs.delete(:id) # ID doesn't exist. Remove it so a new record is created.
      end
    end
    (existing_values_ids - seen_ids).each do |id_to_delete|
      attributes.unshift({ id: id_to_delete, _destroy: '1' })
    end

    { "#{attribute_name}_attributes" => attributes }
  end
end
