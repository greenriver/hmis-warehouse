###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ClientProcessor < Base
    # DO NOT CHANGE: Frontend code sends these values
    # Indicates that a new MCI ID should be created.
    MCI_CREATE_MCI_ID_VALUE = '_CREATE_MCI_ID'.freeze

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
      when 'veteran_status'
        # Veteran status is non-nullable. It should be saved as 99 even if hidden. (It's hidden for minors)
        { attribute_name => attribute_value || 99 }
      when 'age_range'
        # Prioritize exact DOB if it is provided
        process_age_range(value) unless @hud_values.key?('Client.dob') && @hud_values['Client.dob'].present?
      else
        { attribute_name => attribute_value }
      end

      client.assign_attributes(attributes)
    end

    def factory_name
      :client_factory
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
      # Drop names that don't have any meaningful values
      values = Array.wrap(value).filter do |v|
        raise "Expected Hash, found #{v.class.name}" unless v.is_a?(Hash)

        v.slice('first', 'last', 'middle', 'primary').compact_blank.any?
      end

      primary = values.find { |v| v['primary'] == true }
      # Build attributes for Client based on the Primary name
      client_attributes = if primary.present?
        {
          # Note: This logic for transforming CustomClientName attributes to Client attributes is duplicated with the Client model method assign_primary_name_fields
          first_name: primary['first'],
          last_name: primary['last'],
          middle_name: primary['middle'],
          name_suffix: primary['suffix'],
          name_data_quality: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::NameDataQuality, primary['nameDataQuality']) || 99,
        }
      else
        {}
      end

      # Build attributes for CustomClientName record(s)
      name_attributes = construct_nested_attributes(field, values, additional_attributes: related_record_attributes)

      name_attributes.merge(client_attributes)
    end

    private def process_age_range(value)
      case value
      when *HudUtility2024.age_range.keys
        # value matches a known age range, so process it onto dob with low DQ
        { dob: approximate_dob(value), dob_data_quality: 2 }
      when *HudUtility2024.dob_data_quality_options.values_at(8, 9, 99)
        # value matches a known missing data reason, so store that. (not currently expected but future-proofing for desired pick lists)
        { dob_data_quality: HudUtility2024.dob_data_quality(value, true, raise_on_missing: true) }
      when /doesn't know|prefers not to answer|not collected/i
        # value string-matches a missing data reason (PIT form is an example), so don't raise and store 99
        { dob_data_quality: 99 }
      else
        # this might be an age range that we don't support processing, so raise
        raise "Unknown value for age range: #{value}"
      end
    end

    private def approximate_dob(value)
      dob_range = HudUtility2024.age_range[value]

      years_ago = if dob_range.end.infinite?
        # For an infinite range like 65+, just use the beginning of the range
        dob_range.begin
      else
        # Otherwise pick something in the middle of the range
        ((dob_range.begin + dob_range.end) / 2).round
      end

      # Set to start of year so it's more obvious that the data quality is low.
      Date.current.beginning_of_year - years_ago.years
    end

    # Custom handler for MCI field
    private def process_mci(value)
      return unless HmisExternalApis::AcHmis::Mci.enabled?

      # If no MCI selection was made, do nothing. Client/Enrollment validators will handle
      # validation if MCI is required in the given context.
      return if value.nil? || value == Base::HIDDEN_FIELD_VALUE

      client = @processor.send(factory_name)

      current_mci_ids = client.ac_hmis_mci_ids
      # If MCI ID hasn't changed, set flag to perform after-save update to send demographic changes to MCI.
      if current_mci_ids.present? && value.in?(current_mci_ids.map(&:value))
        client.update_mci_attributes = true
        return
      end

      # Changing MCI ID is not supported.
      raise 'Client already has an MCI ID' if current_mci_ids.present?

      # If value indicates that a new MCI ID should be created, do that.
      # Actual MCI ID creation happens in an after_save hook on the HmisExternalApis ClientExtension
      if value == MCI_CREATE_MCI_ID_VALUE
        client.create_mci_id = true
        return
      end

      # MCI value should be numeric
      raise 'Invalid MCI ID' unless Float(value)

      # Initialize an ExternalID with this MCI ID
      client.update_mci_attributes = true
      client.external_ids << HmisExternalApis::ExternalId.new(
        value: value,
        remote_credential: HmisExternalApis::AcHmis::Mci.new.creds,
        namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
      )
    end
  end
end
