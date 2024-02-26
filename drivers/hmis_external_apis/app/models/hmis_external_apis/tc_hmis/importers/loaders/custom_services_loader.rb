###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomServicesLoader < BaseLoader
    FILENAME_PATTERN = 'Services *.xlsx'.freeze

    TOUCHPOINT_NAME = 'TouchPoint Name'.freeze
    RESPONSE_ID = 'Response Unique ID_Form ID'.freeze
    ENROLLMENT_ID = 'Unique Enrollment Identifier'.freeze
    DATE_PROVIDED = 'Date take New Format'.freeze
    QUESTION = 'Question'.freeze
    ANSWER = 'Answer'.freeze

    def perform
      @reader.glob(FILENAME_PATTERN).each do |filename|
        process_file(filename)
      end
    end

    private def process_file(filename)
      rows = @reader.rows(filename: filename, header_row_number: 2, field_id_row_number: nil)
      clobber_records(rows) if clobber

      # services is an instance variable because it holds state that is updated by ar_import, and is needed in create_records
      @services = create_services(rows)
      ar_import(service_class, @services.values) # We need to save these first as we need the ids for CDEs

      cdes = create_records(rows)
      ar_import(cde_class, cdes)
    end

    private def clobber_records(rows)
      custom_service_ids = Set.new.tap do |ids|
        rows.each do |row|
          row_field_value = row.field_value(TOUCHPOINT_NAME)
          config = configs[row_field_value]
          next if config.blank?

          ids << generate_service_id(config, row) # Collect only the services in the file to be clobbered
        end
      end
      services = service_class.where(CustomServiceID: custom_service_ids, data_source: data_source.id)

      rails_service_ids = Set.new.tap do |ids|
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

      enrollments = Hmis::Hud::Enrollment.where(data_source_id: data_source.id).index_by(&:enrollment_id)
      service_type_ids = Hmis::Hud::CustomServiceType.where(data_source_id: data_source.id).pluck(:name, :id).to_h

      result = {}.tap do |services|
        rows.each do |row|
          expected += 1

          row_field_value = row.field_value(TOUCHPOINT_NAME)
          config = configs[row_field_value]
          if config.blank?
            log_skipped_row(row, field: TOUCHPOINT_NAME)
            next
          end

          response_id = row.field_value(RESPONSE_ID)

          service_type = config[:service_type]
          service_type_id = service_type_ids[service_type]
          if service_type_id.blank?
            log_info("Service type configuration error: can't find #{service_type}!")
            log_skipped_row(row, field: :service_type)
            next
          end

          row_field_value = row.field_value(ENROLLMENT_ID)
          enrollment = enrollments[row_field_value]
          if enrollment.blank?
            log_skipped_row(row, field: ENROLLMENT_ID)
            next
          end

          actual += 1

          services[response_id] ||= service_class.new(
            CustomServiceID: generate_service_id(config, row),
            EnrollmentID: enrollment.EnrollmentID,
            PersonalID: enrollment.PersonalID,
            UserID: system_hud_user.id,
            DateProvided: parse_date(row.field_value(DATE_PROVIDED)),
            data_source_id: data_source.id,
            custom_service_type_id: service_type_id,
            service_name: service_type,
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
      "#{config[:id_prefix]}-#{row.field_value(RESPONSE_ID)}"
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
          next if config.blank?

          row_field_value = row.field_value(QUESTION)
          if config[:service_fields].keys.include?(row_field_value)
            # Count this row as processed, but it doesn't update anything since it is a service field
            actual += 1
            next
          end

          element = config[:elements][row_field_value]
          if element.blank?
            log_skipped_row(row, field: QUESTION)
            next
          end

          response_id = row.field_value(RESPONSE_ID)
          service = @services[response_id]
          if service.blank?
            log_info("Missing service for response id #{response_id}!")
            log_skipped_row(row, field: RESPONSE_ID)
            next
          end
          actual += 1

          key = element[:key]
          answer = element[:cleaner].call(row.field_value(ANSWER))
          Array.wrap(answer).each do |value|
            cdes << cde_helper.new_cde_record(value: value, owner_type: service_class.name, owner_id: service.id, definition_key: key)
          end
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
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Transportation' => {
          service_type: 'Transportation',
          service_fields: {
            'Cost' => {
              key: :FAAmount,
              cleaner: ->(amount) { amount.to_f },
            },
          },
          id_prefix: 'transport',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Value' => {
              key: :transportation_type,
              cleaner: ->(type) { type },
            },
            'Quantity' => {
              key: :transportation_quantity,
              cleaner: ->(quantity) { quantity.to_i },
            },
            'Note' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Baby Supplies' => {
          service_type: 'Baby Supplies',
          service_fields: {},
          id_prefix: 'baby',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Items' => {
              key: :baby_supplies_items,
              cleaner: ->(items) { items.split('|') },
            },
            'Quantity' => {
              key: :baby_supplies_quantity,
              cleaner: ->(quantity) { quantity.to_i },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Material Goods' => {
          service_type: 'Material Goods / Financial Assistance',
          service_fields: {
            'Amount' => {
              key: :FAAmount,
              cleaner: ->(amount) { amount.to_f },
            },
          },
          id_prefix: 'goods',
          elements: {
            elements: {
              'Contact Location/Method' => {
                key: :service_contact_location,
                cleaner: ->(location) { normalize_location(location) },
              },
              'Assistance type' => {
                key: :financial_assistance_type,
                cleaner: ->(type) { type },
              },
              'Case Notes' => {
                key: :service_notes,
                cleaner: ->(note) { note },
              },
            },
          },
        },
        'Benefits Contacts' => {
          service_type: 'Benefits Contact',
          service_fields: {},
          id_prefix: 'contacts',
          elements: { # TODO: Confirm ETO field names
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
            },
            'Contact Attempt' => {
              key: :service_benefits_contact_attempt,
              cleaner: ->(type) { type },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Benefits Touchpoint' => { # TODO: Confirm ETO field names
          service_type: 'Benefits Service',
          service_fields: {},
          id_prefix: 'benefits',
          elements: {
            'Service' => {
              key: :service_benefits_type,
              cleaner: ->(type) { type },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        '1A-SA Breakfast' => {
          service_type: 'Breakfast',
          service_fields: {},
          id_prefix: 'breakfast',
          elements: {},
        },
        '1A-SA Lunch' => {
          service_type: 'Lunch',
          service_fields: {},
          id_prefix: 'lunch',
          elements: {},
        },
        '1A-SA Dinner' => {
          service_type: 'Dinner',
          service_fields: {},
          id_prefix: 'dinner',
          elements: {},
        },
        'Budgeting/Financial Planning' => {
          service_type: 'Budgeting/Financial Planning',
          service_fields: {},
          id_prefix: 'budgeting',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Type of Contact' => {
              key: :service_contact_type,
              cleaner: ->(type) { normalize_contact(type) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'DH Case Management' => {
          service_type: 'DH Case Management',
          service_fields: {},
          id_prefix: 'dh-cm',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Type of Contact' => {
              key: :service_contact_type,
              cleaner: ->(type) { normalize_contact(type) },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Drug Testing' => {
          service_type: 'Drug Testing',
          service_fields: {},
          id_prefix: 'drug-testing',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Tests provided' => {
              key: :service_drug_tests_provided,
              cleaner: ->(tests) { tests.split('|') },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Individual TBSS' => {
          service_type: 'Individual TBSS',
          service_fields: {},
          id_prefix: 'tbss',
          elements: {
            'Individual' => {
              key: :service_contact_type,
              cleaner: ->(type) { normalize_contact(type) },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Life Skill Group' => {
          service_type: 'Life Skill Group',
          service_fields: {},
          id_prefix: 'life-skills',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Medication Supervision' => {
          service_type: 'Medication Supervision',
          service_fields: {},
          id_prefix: 'medication',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Value' => {
              key: :medication_supervision_value,
              cleaner: ->(value) { yn_boolean(value) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
        },
        'Substance Abuse Individual' => {
          service_type: 'Substance Abuse Individual',
          service_fields: {},
          id_prefix: 'substance-abuse',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
            },
            'Case Notes' => {
              key: :service_notes,
              cleaner: ->(note) { note },
            },
          },
          'Support Groups (Tenant Support Services)' => {
            service_type: 'Tenant Support Group',
            service_fields: {},
            id_prefix: 'tenant',
            elements: {
              'Service Location' => {
                key: :service_location_text,
                cleaner: ->(service_location) { service_location },
              },
              'Time Spent' => {
                key: :service_time_spent,
                cleaner: ->(time) { parse_duration(time) },
              },
            },
          },
          'Case Management/Case Management notes' => {
            service_type: 'When We Love',
            service_fields: {
              'Assistance Amount' => {
                key: :FAAmount,
                cleaner: ->(amount) { amount.to_f },
              },
            },
            id_prefix: 'cm-notes',
            elements: {
              'Contact Location/Method' => {
                key: :service_contact_location,
                cleaner: ->(location) { normalize_location(location) },
              },
              'Time Spent' => {
                key: :service_time_spent,
                cleaner: ->(time) { parse_duration(time) },
              },
              'Type of Contact' => {
                key: :service_contact_type,
                cleaner: ->(type) { normalize_contact(type) },
              },
              'When We Love Services Provided' => {
                key: :services_provided_when_we_love,
                cleaner: ->(services) { services.split('|') },
              },
            },
          },
        },
      }.freeze
    end

    private def normalize_location(location)
      location # TODO
    end

    private def normalize_contact(contact)
      contact # TODO
    end

    private def service_class
      Hmis::Hud::CustomService
    end

    private def cde_class
      Hmis::Hud::CustomDataElement
    end
  end
end
