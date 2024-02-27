# frozen_string_literal: true

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# CustomDataElementDefinitions.find(key)
module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomClientDemographicsLoader < BaseLoader
    def initialize(...)
      super

      create_cdeds
      @element_definitions = cded_source.where(
        owner_type: client_source.name,
        data_source_id: data_source.id,
        key: demographics_on_client.keys,
      ).map { |defn| [defn.key.to_sym, defn] }.
        to_h
      @stored_demographic_elements = {}
      @client_lookup = client_source.
        where(data_source_id: data_source.id).
        pluck(:personal_id, :id).
        to_h
      @stored_contact_points = {}
      @stored_postal_codes = {}
      @new_postal_codes = []
    end

    def filename
      'Demographic export report.xlsx'
    end

    def runnable?
      reader.file_present?(filename)
    end

    def perform
      rows = @reader.rows(filename: filename, header_row_number: 4, field_id_row_number: nil)

      clobber_records(rows) if clobber

      actual = 0
      expected = 0
      rows.each do |row|
        expected += 1
        personal_id = row.field_value('Participant Enterprise Identifier')
        timestamp = parse_date(row.field_value('Date Last Updated'))
        next unless row_id(row)

        client_id = @client_lookup[personal_id]
        log_skipped_row(row, field: 'Participant Enterprise Identifier') unless client_id
        next unless client_id

        actual += 1
        demographics_on_client.each do |key, field_name|
          update_demographic(
            row: row,
            client_id: client_id,
            timestamp: timestamp,
            demographic_key: key,
            value: row.field_value(field_name),
          )
        end

        update_contact_points(row, personal_id, row.field_value('Cell Phone'), row.field_value('Email'), timestamp)

        update_client_address(row, personal_id, row.field_value('Address Line 1'), row.field_value('Address Line 2'), row.field_value('Zipcode'), timestamp)
      end
      log_processed_result(name: 'Client Demographics', expected: expected, actual: actual)

      cdes_to_insert = transform_demographic_elements
      @stored_demographic_elements = nil
      GC.start
      ar_import(cde_source, cdes_to_insert) if cdes_to_insert.present?

      contact_points_to_insert = @stored_contact_points.values.flatten
      ar_import(cccp_source, contact_points_to_insert) if contact_points_to_insert.present?

      ar_import(cca_source, @new_postal_codes) if @new_postal_codes.present?
    end

    # @param [Hash] elements: [client_id][demographic_key] = {value: , timestamp: , row_id: }
    def transform_demographic_elements
      results = []
      @stored_demographic_elements.each_pair do |client_id, demographics|
        demographics.each_pair do |demographic_key, element|
          results << cde_helper.new_cde_record(
            value: element.fetch(:value),
            owner_type: client_source.name,
            owner_id: client_id,
            definition_key: demographic_key,
            date_created: element.fetch(:timestamp),
          )
        end
      end
      results
    end

    private def clobber_records(rows)
      personal_ids = rows.map { |row| row.field_value('Participant Enterprise Identifier') }.compact_blank.uniq
      demographic_element_ids = @element_definitions.values.map(&:id)
      relevant_cdes = cde_source.where(
        owner_type: 'Hmis::Hud::Client',
        data_element_definition_id: demographic_element_ids,
        data_source_id: data_source.id,
      )
      relevant_cdes.delete_all

      relevant_contacts = cccp_source.where(data_source_id: data_source.id, PersonalID: personal_ids, system: [:phone, :email])
      relevant_contacts.delete_all

      relevant_ccas = cca_source.where(data_source_id: data_source.id, PersonalID: personal_ids)
      relevant_ccas.delete_all
    end

    private def update_demographic(row:, client_id:, timestamp:, demographic_key:, value:)
      return unless value.present? # Do we want to keep last collected, or erase any that are blank w/ newest timestamp?

      element = @stored_demographic_elements.dig(client_id, demographic_key)

      if element.present?
        if element.fetch(:timestamp) == timestamp
          # tie break with row id
          return unless element.fetch(:row_id) < row_id(row)
        else
          # ignore demographics with older timestamps
          return unless element.fetch(:timestamp) < timestamp
        end
      end

      @stored_demographic_elements[client_id] ||= {}
      @stored_demographic_elements[client_id][demographic_key] = { value: value, timestamp: timestamp, row_id: row_id(row) }
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

    def create_cdeds
      demographics_on_client.each_pair do |key, label|
        cde_helper.find_or_create_cded(
          owner_type: client_source.name,
          key: key,
          field_type: label =~ /date/i ? 'date' : 'string',
          repeats: false,
          label: label,
        )
      end
    end

    private def update_contact_points(row, personal_id, phone_number, email, timestamp)
      @stored_contact_points[personal_id] ||= []
      if phone_number.present? && ! @stored_contact_points[personal_id].detect { |c| c[:system].to_s == 'phone' && c[:value] == phone_number }
        @stored_contact_points[personal_id] << {
          use: nil,
          system: :phone,
          value: phone_number,
          notes: nil,
          ContactPointID: "import-phone-#{row_id(row)}",
          PersonalID: personal_id,
          UserID: system_user_id,
          data_source_id: data_source.id,
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
          ContactPointID: "import-email-#{row_id(row)}",
          PersonalID: personal_id,
          UserID: system_user_id,
          data_source_id: data_source.id,
          DateCreated: timestamp,
          DateUpdated: timestamp,
          DateDeleted: nil,
        }
      end
    end

    private def update_client_address(row, personal_id, _line1, _line2, zipcode, timestamp)
      return unless zipcode

      # 2/13/24 -- TC decided they didn't need address information except zipcode
      # TODO: before enabling, address cleaning confirm that there are no privacy issues associated with exposing the data to Nominatim/OpenStreetMap
      #
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
      return if @stored_postal_codes[personal_id]&.include?(zipcode)

      @stored_postal_codes[personal_id] ||= []
      @stored_postal_codes[personal_id] << zipcode

      @new_postal_codes << {
        PersonalID: personal_id,
        postal_code: zipcode,
        AddressID: "import-zip-#{row_id(row)}",
        UserID: system_user_id,
        data_source_id: data_source.id,
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

    private def cca_source
      Hmis::Hud::CustomClientAddress
    end

    private def cccp_source
      Hmis::Hud::CustomClientContactPoint
    end

    private def cde_source
      Hmis::Hud::CustomDataElement
    end

    private def client_source
      Hmis::Hud::Client
    end

    private def cded_source
      Hmis::Hud::CustomDataElementDefinition
    end

    private def row_id(row)
      row.field_value('Unique Enrollment Number')
    end
  end
end
