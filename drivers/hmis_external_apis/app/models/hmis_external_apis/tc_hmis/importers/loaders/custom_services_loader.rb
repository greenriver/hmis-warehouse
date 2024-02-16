###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomServicesLoader < BaseLoader
    FILENAME = 'test.xlsx'.freeze

    TOUCHPOINT_NAME = 'TouchPoint Name'.freeze
    RESPONSE_ID = 'Response ID'.freeze
    ENROLLMENT_ID = 'Enrollment ID'.freeze
    DATE_PROVIDED = 'Date Provided'.freeze
    QUESTION = 'Question'.freeze
    ANSWER = 'Answer'.freeze

    def perform
      rows = @reader.rows(filename: FILENAME, field_id_row_number: nil)
      clobber_records(rows) if clobber

      @services = create_services(rows)
      ar_import(service_class, @services.values) # We need to save these first as we need the ids for CDEs

      @cdes = create_records(rows)
      ar_import(cde_class, @cdes)
    end

    private def clobber_records(rows)
      custom_service_ids = [].tap do |ids|
        rows.each do |row|
          row_field_value = row.field_value(TOUCHPOINT_NAME)
          config = configs[row_field_value]
          if config.blank?
            log_skipped_row(row, field: row_field_value)
            next
          end
          ids << generate_service_id(config, row)
        end
      end
      services = service_class.where(CustomServiceID: custom_service_ids)

      rails_service_ids = [].tap do |ids|
        services.find_each do |service|
          ids << service.id
        end
      end

      services.delete_all

      cdes = cde_class.where(owner_type: service_class.name, owner_id: rails_service_ids)
      cdes.delete_all
    end

    private def create_services(rows)
      log_info('creating services')
      expected = 0
      actual = 0

      enrollments = Hmis::Hud::Enrollment.where(data_source_id: data_source.id).all.map { |en| [en.EnrollmentID, en] }.to_h
      service_type_ids = Hmis::Hud::CustomServiceType.pluck(:name, :id).to_h

      result = {}.tap do |services|
        rows.each do |row|
          expected += 1

          row_field_value = row.field_value(TOUCHPOINT_NAME)
          config = configs[row_field_value]
          if config.blank?
            log_skipped_row(row, field: row_field_value)
            next
          end

          response_id = row.field_value(RESPONSE_ID)

          service_type_id = service_type_ids[config[:service_type]]

          row_field_value = row.field_value(ENROLLMENT_ID)
          enrollment = enrollments[row_field_value]
          if enrollment.blank?
            log_skipped_row(row, field: row_field_value)
            next
          end

          actual += 1

          services[response_id] ||= service_class.new(
            CustomServiceID: generate_service_id(config, row),
            EnrollmentID: enrollment.EnrollmentID,
            PersonalID: enrollment.client.PersonalID,
            UserID: system_hud_user.id,
            DateProvided: parse_date(row.field_value(DATE_PROVIDED)),
            data_source_id: data_source.id,
            custom_service_type_id: service_type_id,
            DateCreated: today,
            DateUpdated: today,
            FAAmount: nil,
            FAStartDate: nil,
            FAEndDate: nil,
          )

          service_field = config[:service_fields][row.field_value(QUESTION)]
          next unless service_field.present? # Don't log this, if there is a problem, we will find it in create_records

          value = service_field[:cleaner].call(row.field_value(ANSWER))

          services[response_id][service_field[:key]] = value
        end
      end
      log_processed_result(name: 'create services', expected: expected, actual: actual)
      result
    end

    private def generate_service_id(config, row)
      "#{config[:id_prefix]}-#{row[:row_number]}"
    end

    private def create_records(rows)
      log_info('creating custom data elements')
      expected = 0
      actual = 0

      records = [].tap do |cdes|
        expected += 1
        rows.each do |row|
          row_field_value = row.field_value(TOUCHPOINT_NAME)
          config = configs[row_field_value]
          if config.blank?
            log_skipped_row(row, field: row_field_value)
            next
          end

          row_field_value = row.field_value(QUESTION)
          if config[:service_fields].keys.include?(row_field_value)
            # Count this row as processed, but it doesn't update anything since it is a service field
            actual += 1
            next
          end

          element = config[:elements][row_field_value]
          if element.blank?
            log_skipped_row(row, field: row_field_value)
            next
          end

          actual += 1
          service = @services[row.field_value(RESPONSE_ID)]

          key = element[:key]
          value = element[:cleaner].call(row.field_value(ANSWER))
          cdes << cde_helper.new_cde_record(value: value, owner_type: service_class.name, owner_id: service.id, definition_key: key)
        end
      end
      log_processed_result(name: 'create cdes', expected: expected, actual: actual)
      records
    end

    private def configs
      {
        'Food Box-Groceries' => {
          service_type: 'Food Box / Groceries',
          service_fields: {},
          id_prefix: 'food-box',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Number of pantry bags' => {
              key: :food_service_pantry_bags_quantity,
              cleaner: ->(quantity) { quantity.to_i },
            },
            'Number of people in the household' => {
              key: :food_service_household_size,
              cleaner: ->(size) { size.to_i },
            },
          },
        },
      }.freeze
    end

    private def normalize_location(location)
      location # TODO
    end

    private def service_class
      Hmis::Hud::CustomService
    end

    private def cde_class
      Hmis::Hud::CustomDataElement
    end
  end
end
