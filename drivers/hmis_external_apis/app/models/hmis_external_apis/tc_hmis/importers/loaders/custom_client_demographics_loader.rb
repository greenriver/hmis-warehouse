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
      @stored_postal_codes = {}
      @new_postal_codes = []
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

        update_client_address(personal_id, row.field_value('Address Line 1'), row.field_value('Address Line 2'), row.field_value('Zipcode'), timestamp)
      end
      Hmis::Hud::CustomDataElement.upsert_all(
        @stored_demographic_elements.values.map(&:values).flatten,
        unique_by: :id,
      )

      Hmis::Hud::CustomClientContactPoint.upsert_all(
        @stored_contact_points.values.flatten,
        unique_by: :id,
      )

      Hmis::Hud::CustomClientAddress.insert_all(@new_postal_codes)
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

    private def update_client_address(personal_id, _line1, _line2, zipcode, timestamp)
      return unless @client_lookup[personal_id].present? # Skip non-existent clients

      # 2/13/24 -- TC decided they didn't need address information except zipcode
      # query = [line1, line2].compact.join(' ') || zipcode # send zipcode if we don't have anything else
      # query = [query, zipcode].compact.join(' ') unless query.match(/\d+$/) # Add the zip if we don't see a number
      # result = nominatim_lookup(query)
      # return unless result.present?
      #
      # line1 = [result.house_number, result.street].join(' ')
      # city = result.city
      # # Need to store 2 letter codes, which is not what Nominatim returns as state
      # state = result.data.dig('address', 'ISO3166-2-lvl4')[-2..]

      # Don't duplicate zipcodes
      @stored_postal_codes[personal_id] ||= Hmis::Hud::CustomClientAddress.where(PersonalID: personal_id).where.not(postal_code: nil).pluck(:postal_code)
      return if @stored_postal_codes[personal_id].include?(zipcode)

      @stored_postal_codes[personal_id] << zipcode

      @new_postal_codes << {
        PersonalID: personal_id,
        postal_code: zipcode,
        AddressID: Hmis::Hud::Base.generate_uuid,
        UserID: @user_id,
        data_source_id: @data_source_id,
        DateCreated: timestamp,
        DateUpdated: timestamp,
      }
    end

    private def nominatim_lookup(query)
      return if Rails.cache.read(['Nominatim', 'API PAUSE'])

      address = [query, 'US'].compact.join(',')
      n = Geocoder.search(address)

      # Limit calls to 1 per second (we are defaulting to using Nominatim, and this is their policy)
      @rate_limit ||= Time.new(0)
      sleep 1 if (Time.current - @rate_limit) < 1
      result = n.first
      @rate_limit = Time.current

      return result
    rescue Faraday::ConnectionFailed
      # we've probably been banned, let the API cool off
      Rails.cache.write(['Nominatim', 'API PAUSE'], true, expires_in: 1.hours)
    rescue StandardError => e
      # The API returns various errors which we don't want to prevent continuing with other attempts.
      # Just send it along to sentry and take a quick break
      Sentry.capture_exception(e)
      sleep 1
    end
  end
end
