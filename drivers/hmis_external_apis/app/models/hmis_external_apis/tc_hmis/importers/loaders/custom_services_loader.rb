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

    def runnable?
      super && @reader.glob(FILENAME_PATTERN).any?
    end

    def row_date_provided(row)
      parse_date(row.field_value(DATE_PROVIDED))
    end

    def row_personal_id(row)
      normalize_uuid(row.field_value('Participant Enterprise Identifier'))
    end

    def perform
      if clobber
        @reader.glob(FILENAME_PATTERN).each do |filename|
          rows = @reader.rows(filename: filename, header_row_number: 2, field_id_row_number: nil)
          clobber_records(rows)
        end
      end
      @reader.glob(FILENAME_PATTERN).each do |filename|
        process_file(filename)
      end
    end

    private def process_file(filename)
      create_service_types
      create_cdeds
      rows = @reader.rows(filename: filename, header_row_number: 2, field_id_row_number: nil).to_a
      clear_invalid_enrollment_ids(rows, enrollment_id_field: ENROLLMENT_ID)
      extrapolate_missing_enrollment_ids(rows, enrollment_id_field: ENROLLMENT_ID)

      # services is an instance variable because it holds state that is updated by ar_import, and is needed in create_records
      @services = create_services(rows)
      ar_import(service_class, @services.values) # We need to save these first as we need the ids for CDEs

      cdes = create_records(rows)
      ar_import(cde_class, cdes)
    end

    private def create_service_types
      # service types should already exist on production
      return unless Rails.env.development?

      configs.values.each do |value|
        Hmis::Hud::CustomServiceType.where(data_source_id: data_source.id).where(name: value.fetch(:service_type)).first_or_create! do |st|
          st.UserID = system_hud_user.user_id
          st.custom_service_category_id = placeholder_service_category.id
        end
      end
    end

    private def create_cdeds
      configs.each_value do |config|
        config[:elements].each_value do |element_config|
          cde_helper.find_or_create_cded(
            owner_type: service_class.name,
            key: element_config.fetch(:key),
            field_type: element_config.fetch(:field_type, 'string'),
            repeats: element_config[:repeats],
          )
        end
      end
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
      services = service_class.where(CustomServiceID: custom_service_ids, data_source_id: data_source.id)

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
      expected = Set.new

      enrollments = Hmis::Hud::Enrollment.where(data_source_id: data_source.id).index_by(&:enrollment_id)
      service_type_ids = Hmis::Hud::CustomServiceType.where(data_source_id: data_source.id).pluck(:name, :id).to_h

      result = {}.tap do |services|
        rows.each do |row|
          response_id = row.field_value(RESPONSE_ID, required: true)
          expected.add(response_id)

          touch_point_name = row.field_value(TOUCHPOINT_NAME, required: true)
          config = configs[touch_point_name]
          if config.blank?
            log_skipped_row(row, field: TOUCHPOINT_NAME)
            next
          end

          service_type = config[:service_type]
          service_type_id = service_type_ids[service_type]
          if service_type_id.blank?
            log_info("Service type configuration error: can't find #{service_type}!")
            next
          end

          row_field_value = row_enrollment_id(row)
          enrollment = row_field_value ? enrollments[row_field_value] : nil
          enrollment = enrollments.values.first
          if enrollment.blank?
            log_skipped_row(row, field: ENROLLMENT_ID, prefix: touch_point_name)
            next
          end

          date_provided = row_date_provided(row)
          # derived "last updated" timestamp for 9am on DateProvided
          last_updated_timestamp = date_provided.beginning_of_day.to_datetime + 9.hours
          services[response_id] ||= service_class.new(
            CustomServiceID: generate_service_id(config, row),
            EnrollmentID: enrollment.EnrollmentID,
            PersonalID: enrollment.PersonalID,
            UserID: system_hud_user.user_id,
            DateProvided: row_date_provided(row),
            data_source_id: data_source.id,
            custom_service_type_id: service_type_id,
            service_name: service_type,
            DateCreated: last_updated_timestamp,
            DateUpdated: last_updated_timestamp,
            FAAmount: nil,
            FAStartDate: nil,
            FAEndDate: nil,
          )

          service_field = config[:service_fields][row.field_value(QUESTION)]
          next unless service_field.present? # Don't log this, if there is a problem, we will find it in create_records

          services[response_id][service_field[:key]] = cleaned_row_answer(row, service_field)
        end
      end
      log_processed_result(name: 'create services', expected: expected.size, actual: result.size)
      result
    end

    private def generate_service_id(config, row)
      "#{config[:id_prefix]}-#{row.field_value(RESPONSE_ID)}"
    end

    def cleaned_row_answer(row, service_field)
      row_value = row.field_value(ANSWER)
      return nil unless row_value

      service_field[:cleaner] ? service_field[:cleaner].call(row_value) : row_value
    end

    def row_question_value(row)
      # there are new lines in some questions labels. Return just the first line
      value = row.field_value(QUESTION)
      value ? value.split("\n").detect(&:present?).strip : nil
    end

    def row_enrollment_id(row)
      normalize_uuid(row.field_value(ENROLLMENT_ID))
    end

    private def create_records(rows)
      log_info('creating custom data elements')
      expected = 0
      actual = 0

      seen = Set.new
      records = [].tap do |cdes|
        rows.each do |row|
          expected += 1
          touch_point_name = row.field_value(TOUCHPOINT_NAME)
          config = configs[touch_point_name]
          next if config.blank?

          seen.add(touch_point_name)

          row_field_value = row_question_value(row)
          if config[:service_fields].keys.include?(row_field_value)
            # Count this row as processed, but it doesn't update anything since it is a service field
            actual += 1
            next
          end

          element = config[:elements][row_field_value]
          if element.blank?
            log_skipped_row(row, field: QUESTION, prefix: touch_point_name)
            next
          end

          response_id = row.field_value(RESPONSE_ID, required: true)
          service = @services[response_id]
          next if service.blank?

          actual += 1

          key = element[:key]
          answer = cleaned_row_answer(row, element)
          Array.wrap(answer).each do |value|
            cdes << cde_helper.new_cde_record(value: value, owner_type: service_class.name, owner_id: service.id, definition_key: key)
          end
        end
      end
      log_processed_result(name: 'create cdes', expected: expected, actual: actual)
      missed = configs.keys - seen.to_a
      log_info("did not find any values for #{missed.size} of #{configs.size} touchpoints: #{missed.sort.join(', ')}") if missed.any?
      records
    end

    private def configs
      {
        'Employment Recruiter Service' => {
          service_type: 'Employment Recruiter Service',
          service_fields: {},
          id_prefix: 'employment_recruiter_service',
          elements: {
            'Staff Name:' => {
              key: 'employment_recruiter_service_staff_name',
            },
            'Notes:' => {
              key: 'service_note',
            },
            'Time Spent:' => {
              key: 'service_time_spent',
              field_type: :integer,
            },
          },
        },
        'TB and Buss Pass' => {
          service_type: 'TB and Bus Pass',
          service_fields: {},
          id_prefix: 'employment_recruiter_service',
          elements: {
            'Contact Location/Method:' => {
              key: 'service_contact_location',
            },
          },
        },
        'PNS Moving Home Services' => {
          service_type: 'PNS Moving Home Services',
          service_fields: {},
          id_prefix: 'pns_moving_home_services',
          elements: {
            'Services' => {
              key: 'pns_moving_home_services',
              cleaner: ->(services) { services.split('|') },
              repeats: true,
            },
            'Case Notes' => {
              key: 'service_note',
            },
            'Contact Location/Method' => {
              key: 'service_contact_location',
            },
            'Time Spent' => {
              key: 'service_time_spent',
              field_type: :integer,
            },
          },
        },
        'When We Love' => {
          service_type: 'TB and Bus Pass',
          service_fields: {
            #'Amount ( If Needed )' => {
            'The amount Assistance' => {
              key: :FAAmount,
              cleaner: ->(amount) { amount.to_f },
            },
          },
          id_prefix: 'when-we-love',
          elements: {
            'Client note' => {
              key: :service_note,
            },
            'Assistance' => {
              key: :when_we_love_assistance_type,
              cleaner: ->(services) { services.split('|') },
            },
          },
        },
        'DRC Critical Documents (Services)' => {
          service_type: 'DRC Critical Documents',
          service_fields: {},
          id_prefix: 'drc_critical_document_service',
          elements: {
            'Critical Document Service' => {
              key: 'drc_critical_document_service',
              cleaner: ->(services) { services.split('|') },
              repeats: true,
            },
            'Document Obtainment' => {
              key: 'drc_critical_document_service_document_type',
              cleaner: ->(services) { services.split('|') },
              repeats: true,
            },
            'Case Notes' => {
              key: :service_note,
            },
            'How Many Birth Certificate ?' => {
              key: 'drc_critical_document_num_birth_certificate',
              field_type: :integer,
            },
            'How Many State ID ?' => {
              key: 'drc_critical_document_num_state_id',
              field_type: :integer,
            },
            'How Many Driver Licenses ?' => {
              key: 'drc_critical_document_num_driver_license',
              field_type: :integer,
            },
            'How Many Social Security ?' => {
              key: 'drc_critical_document_num_social_security',
              field_type: :integer,
            },
            "How many Voter's Registration cards?" => {
              key: 'drc_critical_document_num_voter_registration_cards',
              field_type: :integer,
            },
          },
        },
        'Food Box - Groceries' => {
          service_type: 'Food Box / Groceries',
          service_fields: {},
          id_prefix: 'food-box',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Number of Pantry Bags' => {
              key: :food_service_pantry_bags_quantity,
              cleaner: ->(quantity) { quantity.to_i },
              field_type: :integer,
            },
            'Number of people in the household' => {
              key: :food_service_household_size,
              cleaner: ->(size) { size.to_i },
              field_type: :integer,
            },
            'Case Notes' => {
              key: :service_note,
            },
          },
        },
        'Transportation' => {
          service_type: 'Transportation',
          service_fields: {
            'Cost' => {
              key: :FAAmount,
              cleaner: ->(amount) { amount.to_f },
              field_type: :float,
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
            },
            'Quantity' => {
              key: :transportation_quantity,
              cleaner: ->(quantity) { quantity.to_i },
              field_type: :integer,
            },
            'Case Notes' => {
              key: :service_note,
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
              repeats: true,
            },
            'Quantity' => {
              key: :baby_supplies_quantity,
              cleaner: ->(quantity) { quantity.to_i },
              field_type: :integer,
            },
            'Case Notes' => {
              key: :service_note,
            },
          },
        },
        'Material Goods' => {
          service_type: 'Material Goods / Financial Assistance',
          service_fields: {
            'Amount ( If Needed )' => {
              key: :FAAmount,
              cleaner: ->(amount) { amount.to_f },
            },
          },
          id_prefix: 'goods',
          elements: {
            'Contact Location/Method' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Value' => {
              key: :financial_assistance_type,
            },
            'Case Notes' => {
              key: :service_note,
            },
          },
        },
        'Benefits Contacts' => {
          service_type: 'Benefits Contact',
          service_fields: {},
          id_prefix: 'contacts',
          elements: {
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
              field_type: :integer,
            },
            '.' => { # label in eto is just a period
              key: :service_benefits_contact_attempt,
            },
            'Notes:' => {
              key: :service_note,
            },
          },
        },
        'Benefits Touchpoint' => {
          service_type: 'Benefits Service',
          service_fields: {},
          id_prefix: 'benefits',
          elements: {
            'Service' => {
              key: :service_benefits_type,
            },
            'Time Spent total time spend working with the client in person or on their behalf.' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
              field_type: :integer,
            },
            'Monthly SSI/SSDI Payment/Retirement' => {
              key: :service_benefits_ssi,
              field_type: :float,
            },
            'Lump Payment' => {
              key: :service_lump_payment,
              field_type: :float,
            },
            'SNAPS Amount' => {
              key: :service_snaps_amount,
              field_type: :float,
            },
            'Note' => {
              key: :service_note,
            },
          },
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
              key: :service_note,
            },
          },
        },
        'DH Case Management' => {
          service_type: 'DH Case Management',
          service_fields: {},
          id_prefix: 'dh-cm',
          elements: {
            'Service Location' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Type of Contact (Must correctly classify type of contact)' => {
              key: :service_contact_type,
              cleaner: ->(type) { normalize_contact(type) },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
              field_type: :integer,
            },
            'Case Notes' => {
              key: :service_note,
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
            'Value' => {
              key: :service_drug_tests_provided,
              cleaner: ->(tests) { tests.split('|') },
              repeats: true,
            },
            'Case Notes' => {
              key: :service_note,
            },
          },
        },
        'Individual TBSS' => {
          service_type: 'TBSS',
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
              key: :service_note,
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
            'Time Spend' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
              field_type: :integer,
            },
            'Case Notes' => {
              key: :service_note,
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
              field_type: :boolean,
            },
            'Case Notes' => {
              key: :service_note,
            },
          },
        },
        'Support Groups (Tenant Support Services)' => {
          service_type: 'Tenant Support Group',
          service_fields: {},
          id_prefix: 'tenant',
          elements: {
            'Service Location' => {
              key: :service_location_text,
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
              field_type: :integer,
            },
          },
        },
        'Case Management/ Case Management Notes' => {
          service_type: 'When We Love',
          service_fields: {
            'Assistance Amount' => {
              key: :FAAmount,
              cleaner: ->(amount) { amount.to_f },
            },
          },
          id_prefix: 'cm-notes',
          elements: {
            'Service Location' => {
              key: :service_contact_location,
              cleaner: ->(location) { normalize_location(location) },
            },
            'Time Spent' => {
              key: :service_time_spent,
              cleaner: ->(time) { parse_duration(time) },
              field_type: :integer,
            },
            'Type of Contact' => {
              key: :service_contact_type,
              cleaner: ->(type) { normalize_contact(type) },
            },
            'When We Love: Services Provided' => {
              key: :services_provided_when_we_love,
              cleaner: ->(services) { services.split('|') },
              repeats: true,
            },
            'Case Notes' => {
              key: :service_note,
            },
          },
        },
        'Substance Abuse Individual' => substance_abuse_config,
        'Substance Abuse Group' => substance_abuse_config,
      }.freeze
    end

    # several services user this same config, they are imported to the same service
    def substance_abuse_config
      {
        service_type: 'Substance Abuse',
        service_fields: {},
        id_prefix: 'substance-abuse',
        elements: {
          'Contact Location/Method' => {
            key: :service_contact_location,
            cleaner: ->(location) { normalize_location(location) },
          },
          'Time Spent on Contact' => {
            key: :service_time_spent,
            cleaner: ->(time) { parse_duration(time) },
            field_type: :integer,
          },
          'Case Notes' => {
            key: :service_note,
          },
        },
      }.dup.freeze
    end

    private def normalize_location(location)
      return if location&.blank?

      cleaned = location.downcase.gsub(/[^A-Za-z]/, ' ').strip
      if cleaned.include?('non residential')
        'Service setting, Non Residential'
      elsif cleaned.include?('residential')
        'Service setting, Residential'
      elsif cleaned.include?('habitation')
        'Place not meant for habitation'
      else
        location
      end
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
