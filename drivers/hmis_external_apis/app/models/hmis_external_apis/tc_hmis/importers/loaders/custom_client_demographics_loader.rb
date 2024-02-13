###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# CustomDataElementDefinitions.find(key)
module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomClientDemographicsLoader
    def initialize(directory, filename, data_source_id, user_id: User.system_user.id)
      @directory = directory
      @filename = filename
      @data_source_id = data_source_id
      @user_id = user_id

      @element_definitions = Hmis::Hud::CustomDataElementDefinition.where(
        owner_type: 'Hmis::Hud::Client',
        data_source_id: @data_source_id,
        key: demographics_on_client.map { |key, _| key },
      ).map { |defn| [defn.key.to_sym, defn] }.
        to_h
      @stored_demographic_elements = {}
      @client_lookup = Hmis::Hud::Client.
        where(data_source_id: @data_source_id).
        pluck(:personal_id, :id).
        to_h
      @stored_contact_points = {}
    end

    def process
      reader = HmisExternalApis::TcHmis::Importers::Loaders::FileReader.new(@directory)
      reader.rows(filename: @filename, header_row_number: 4, field_id_row_number: 1).each do |row|
        personal_id = row.field_value('Participant Enterprise Identifier')
        timestamp = row.field_value('Date Last Updated').to_date

        demographics_on_client.each do |key, field_name|
          update_demographic(
            client_id: @client_lookup[personal_id],
            timestamp: timestamp,
            demographic_key: key,
            value: row.field_value(field_name),
          )
        end

        update_contact_points(personal_id, row.field_value('Cell Phone'), row.field_value('Email'), timestamp)
      end
      Hmis::Hud::CustomDataElement.upsert_all(
        @stored_demographic_elements.values.map(&:values).flatten,
        unique_by: :id,
      )

      Hmis::Hud::CustomClientContactPoint.upsert_all(
        @stored_contact_points.values.flatten,
        unique_by: :id,
      )
    end

    private def update_demographic(client_id:, timestamp:, demographic_key:, value:)
      return unless client_id.present? # Skip non-existent clients
      return unless value.present? # Do we want to keep last collected, or erase any that are blank w/ newest timestamp?

      # Retrieve any existing CDEs for the client -- this will be faster than updating 1 by 1, but slower than
      # retrieving the whole dataset in advance, but will use less memory. If it is too big, we may need to batch the
      # xlsx records
      @stored_demographic_elements[client_id] ||= Hmis::Hud::CustomDataElement.where(owner_type: 'Hmis::Hud::Client', owner_id: client_id).
        map { |e| [e.data_element_definition_id, e.attributes.symbolize_keys] }.
        to_h

      definition = @element_definitions[demographic_key]
      element =  @stored_demographic_elements[client_id][definition.id]
      column = "value_#{definition.field_type}".to_sym

      if element.present?
        return unless element[:DateUpdated] < timestamp

        element[column] = value
        element[:DateUpdated] = timestamp
      else
        element = {
          owner_type: 'Hmis::Hud::Client',
          owner_id: client_id,
          data_source_id: @data_source_id,
          data_element_definition_id: definition.id,
          UserID: @user_id,
          DateCreated: timestamp,
          DateUpdated: timestamp,
          DateDeleted: nil,

          value_float: nil, # Make sure we have all the value columns for the import
          value_integer: nil,
          value_boolean: nil,
          value_string: nil,
          value_text: nil,
          value_date: nil,
          value_json: nil,
        }
        element[column] = value
        @stored_demographic_elements[client_id][definition.id] = element
      end
    end

    private def demographics_on_client
      {
        tb_cleared_date: 'TB Clear Date',
        tb_expiration_date: 'TB Exp. Date',
        tb_flagged_date: 'TB Flagged Date',
        emergency_contact_name: 'Emergency Contact Name_4538',
        emergency_contact_number: 'Emergency Contact Number_4541',
        sexual_orientation: 'Sexual Orientation',
      }.freeze
    end

    private def update_contact_points(personal_id, phone_number, email, timestamp)
      return unless @client_lookup[personal_id].present? # Skip non-existent clients

      @stored_contact_points[personal_id] ||= Hmis::Hud::CustomClientContactPoint.
        where(PersonalID: personal_id, system: [:phone, :email]).
        map { |e| e.attributes.symbolize_keys }

      if phone_number.present? && ! @stored_contact_points[personal_id].detect { |c| c[:system].to_s == 'phone' && c[:value] == phone_number }
        @stored_contact_points[personal_id] << {
          use: nil,
          system: :phone,
          value: phone_number,
          notes: nil,
          ContactPointID: Hmis::Hud::Base.generate_uuid,
          PersonalID: personal_id,
          UserID: @user_id,
          data_source_id: @data_source_id,
          DateCreated: timestamp,
          DateUpdated: timestamp,
          DateDeleted: nil,
        }
      end

      if email.present? && ! @stored_contact_points[personal_id].detect { |c| c[:system].to_s == 'email' && c[:value] == email } # rubocop:disable Style/GuardClause
        @stored_contact_points[personal_id] << {
          use: nil,
          system: :email,
          value: email,
          notes: nil,
          ContactPointID: Hmis::Hud::Base.generate_uuid,
          PersonalID: personal_id,
          UserID: @user_id,
          data_source_id: @data_source_id,
          DateCreated: timestamp,
          DateUpdated: timestamp,
          DateDeleted: nil,
        }
      end
    end

    # { owner_type: 'Hmis::Hud::CustomClientAddress', field_type: :string, key: :postal_code, label: 'Zip code- with extension' },
    # { owner_type: 'Hmis::Hud::CustomClientAddress', field_type: :string, key: :line1, label: 'Address 1' },
    # { owner_type: 'Hmis::Hud::CustomClientAddress', field_type: :string, key: :line1, label: 'Address 2' },
  end
end
