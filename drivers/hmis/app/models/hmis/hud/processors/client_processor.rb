###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ClientProcessor < Base
    # DO NOT CHANGE: Frontend code sends these values
    # Indicates that a new MCI ID should be created.
    MCI_CREATE_MCI_ID_VALUE = '_CREATE_MCI_ID'.freeze
    # Indicates that no MCI ID should be created. Use this instead of null, because the user should be required to make a selection
    MCI_CREATE_UNCLEARED_CLIENT_VALUE = '_CREATE_UNCLEARED_CLIENT'.freeze

    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      # Skip SSN/DOB fields if hidden, because they are always hidden due to lack of permissions (see client.json form definition)
      return if value == Base::HIDDEN_FIELD_VALUE && ['ssn', 'dob'].include?(attribute_name)

      client = @processor.send(factory_name)

      attributes = case attribute_name
      when 'race'
        self.class.race_attributes(Array.wrap(attribute_value))
      when 'gender'
        self.class.gender_attributes(Array.wrap(attribute_value))
      when 'pronouns'
        { attribute_name => Array.wrap(attribute_value).any? ? Array.wrap(attribute_value).join('|') : nil }
      when 'ssn'
        { attribute_name => attribute_value.present? ? attribute_value.gsub(/[^\dXx]/, '') : nil }
      when 'ssn_data_quality'
        # If hidden due to permissions, set to old value or 99
        attribute_value = client.ssn_data_quality || 99 if value == Base::HIDDEN_FIELD_VALUE
        { attribute_name => attribute_value }
      when 'dob_data_quality'
        # If hidden due to permissions, set to old value or 99
        attribute_value = client.dob_data_quality || 99 if value == Base::HIDDEN_FIELD_VALUE
        { attribute_name => attribute_value }
      when 'names'
        process_names(field, value)
      when 'addresses'
        construct_nested_attributes(field, value, additional_attributes: related_record_attributes)
      when 'phone_numbers'
        process_contact_points(value, system: :phone, scope_name: :phones)
      when 'email_addresses'
        process_contact_points(value, system: :email, scope_name: :emails)
      when 'mci_id'
        process_mci(value)
        {}
      else
        { attribute_name => attribute_value }
      end

      client.assign_attributes(attributes)
    end

    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Client
    end

    def information_date(_)
    end

    def self.race_attributes(attribute_value)
      input_to_multi_fields(
        attribute_value,
        Hmis::Hud::Client.race_enum_map,
        :data_not_collected,
        :RaceNone,
      )
    end

    # @param genders [Array<Integer>] HUD gender values
    def self.gender_attributes(attribute_value)
      input_to_multi_fields(
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

    private def related_record_attributes
      {
        user: @processor.hud_user,
        data_source_id: @processor.hud_user.data_source_id,
        client: @processor.send(factory_name),
      }
    end

    private def process_contact_points(value, system:, scope_name:)
      attrs = { **related_record_attributes, system: system }
      construct_nested_attributes('contactPoints', value, additional_attributes: attrs, scope_name: scope_name)
    end

    private def process_names(field, value)
      client = @processor.send(factory_name)
      # Drop names that don't have any meaningful values
      values = Array.wrap(value).filter do |v|
        raise "Expected Hash, found #{v.class.name}" unless v.is_a?(Hash)

        v.slice('first', 'last', 'middle', 'primary').compact_blank.any?
      end

      # Build attributes
      name_attributes = construct_nested_attributes(field, values, additional_attributes: related_record_attributes)

      # Set NameDataQuality to 99, it will be overridden to match primary name in the after_save hook
      name_attributes[:name_data_quality] = 99 unless client.name_data_quality.present?
      name_attributes
    end

    # Custom handler for MCI field
    private def process_mci(value)
      return unless HmisExternalApis::AcHmis::Mci.enabled?
      return if value.nil? # Shouldn't happen, the form validation should ensure presence because it is required

      client = @processor.send(factory_name)
      current_mci_ids = client.ac_hmis_mci_ids
      # If MCI ID hasn't changed, do nothing.
      return if current_mci_ids.present? && value.in?(current_mci_ids.map(&:value))

      # If field is hidden, that means that there was not enough information to clear MCI.
      # Do nothing, which will create an "uncleared" client. If client is already cleared, nothing happens.
      return if value == Base::HIDDEN_FIELD_VALUE

      # If value is MCI_CREATE_MCI_ID_VALUE, that means the use explicitly chose NOT to link or create an MCI ID.
      # Do nothing, which will create an "uncleared" client. If client is already cleared, nothing happens.
      return if value == MCI_CREATE_UNCLEARED_CLIENT_VALUE

      # Changing MCI ID is not supported.
      raise 'Client already has an MCI ID' if current_mci_ids.present?

      # If value indicates that a new MCI ID should be created, do that.
      # Actual MCI ID creation happens in an after_save hook on Client.
      if value == MCI_CREATE_MCI_ID_VALUE
        client.create_mci_id = true
        return
      end

      # MCI value should be numeric
      raise 'Invalid MCI ID' unless Float(value)

      # Initialize an ExternalID with this MCI ID
      client.external_ids << HmisExternalApis::ExternalId.new(
        value: value,
        remote_credential: HmisExternalApis::AcHmis::Mci.new.creds,
        namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
      )
    end
  end
end
