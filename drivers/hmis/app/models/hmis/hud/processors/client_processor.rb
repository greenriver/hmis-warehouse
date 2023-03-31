###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ClientProcessor < Base
    def process(field, value)
      attribute_name = hud_name(field)
      attribute_value = attribute_value_for_enum(hud_type(field), value)

      # Skip SSN/DOB fields if hidden, because they are always hidden due to lack of permissions (see client.json form definition)
      return if value == Base::HIDDEN_FIELD_VALUE && ['ssn', 'dob'].include?(attribute_name)

      attributes = case attribute_name
      when 'race'
        race_attributes(Array.wrap(attribute_value))
      when 'gender'
        gender_attributes(Array.wrap(attribute_value))
      when 'pronouns'
        { attribute_name => Array.wrap(attribute_value).any? ? Array.wrap(attribute_value).join('|') : nil }
      when 'ssn'
        { attribute_name => attribute_value.present? ? attribute_value.gsub(/[^\dXx]/, '') : nil }
      when 'ssn_data_quality'
        # If hidden due to permissions, set to old value or 99
        attribute_value = @processor.send(factory_name).ssn_data_quality || 99 if value == Base::HIDDEN_FIELD_VALUE
        { attribute_name => attribute_value }
      when 'dob_data_quality'
        # If hidden due to permissions, set to old value or 99
        attribute_value = @processor.send(factory_name).dob_data_quality || 99 if value == Base::HIDDEN_FIELD_VALUE
        { attribute_name => attribute_value }
      else
        { attribute_name => attribute_value }
      end

      @processor.send(factory_name).assign_attributes(attributes)
    end

    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Client
    end

    def information_date(_)
    end

    private def race_attributes(attribute_value)
      self.class.input_to_multi_fields(
        attribute_value,
        Hmis::Hud::Client.race_enum_map,
        :data_not_collected,
        :RaceNone,
      )
    end

    private def gender_attributes(attribute_value)
      self.class.input_to_multi_fields(
        attribute_value,
        Hmis::Hud::Client.gender_enum_map,
        'Data not collected',
        :GenderNone,
      )
    end

    def self.multi_fields_to_input(client, input_field, enum_map, none_field)
      none_value = client.send(none_field)
      return { input_field => [none_value] } if none_value.present?

      {
        input_field => enum_map.base_members.
          select { |item| client.send(item[:key]) == 1 }.
          map { |item| item[:value] },
      }
    end

    def self.input_to_multi_fields(input_field, enum_map, not_collected_key, none_field)
      result = {}
      return result if input_field.nil?

      null_value = input_field.find { |val| enum_map.null_member?(value: val) }
      null_value = enum_map.lookup(key: not_collected_key)[:value] if input_field.empty?

      if null_value.nil?
        enum_map.base_members.map { |item| item[:value] }.each do |value|
          member = enum_map.lookup(value: value)
          result[member[:key]] = input_field.include?(value) ? 1 : 0
        end
        result[none_field] = nil
      else
        enum_map.base_members.each do |member|
          result[member[:key]] = 99
        end
        result[none_field] = null_value unless none_field.nil?
      end

      result
    end
  end
end
