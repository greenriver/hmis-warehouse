###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# reload!; reader = HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/sh_hmis/importers'); HmisExternalApis::ShHmis::Importers::Loaders::FlexFundsLoader.new(clobber: false, reader: reader).perform
module HmisExternalApis::ShHmis::Importers::Loaders
  class FlexFundsLoader < SingleFileLoader
    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).each(&:really_destroy!) if clobber

      # can't do bulk insert here since polymorphic CDE's don't seem to work
      # and bulk-insert returned ids are not ordered
      without_paper_trail do
        records.each { |record| record.save!(validate: false) }
      end
      log_info "Inserted #{records.size} records into #{model_class.table_name}"
    end

    def filename
      'FlexFunds.csv'
    end

    protected

    def cde_definitions_keys
      [:flex_funds_types, :flex_funds_other_details]
    end

    def build_records
      # { Unique ID => CustomService record }
      records_by_id = {}

      id_header = 'Response Unique Identifier'
      enrollment_id_header = 'Unique Enrollment Identifier'
      enrollment_id_to_personal_id = Hmis::Hud::Enrollment.where(data_source: data_source)
        .pluck(:enrollment_id, :personal_id)
        .to_h

      expected = 0
      rows.each do |row|
        service_id = row_value(row, field: id_header)
        enrollment_id = row_value(row, field: enrollment_id_header, required: false)
        unless enrollment_id
          log_info "Missing enrollment id. Response identifier: #{id_header}"
          next
        end

        date_provided = row_value(row, field: 'Date Taken')
        personal_id = enrollment_id_to_personal_id[enrollment_id] if enrollment_id
        unless personal_id
          log_skipped_row(row, field: enrollment_id_header)
          next # early return
        end

        expected += 1 unless records_by_id.key?(service_id)

        records_by_id[service_id] ||= model_class.new(
          EnrollmentID: enrollment_id,
          PersonalID: personal_id,
          CustomServiceID: service_id,
          DateProvided: parse_date(date_provided),
          DateCreated: parse_date(date_provided),
          DateUpdated: parse_date(date_provided),
          data_source_id: data_source.id,
          user_id: system_user_id,
          custom_service_type_id: custom_service_type.id,
          service_name: custom_service_type.name,
        )

        cde_attrs(row).each do |attrs|
          records_by_id[service_id].custom_data_elements.build(attrs)
        end
      end
      records = records_by_id.values
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def cde_attrs(row)
      question = row_value(row, field: 'Question')
      answer = row_value(row, field: 'Answer', required: false)
      return [] if answer.blank?

      definition_key = if question.starts_with?('Direct financial')
        :flex_funds_types
      elsif question.starts_with?('Other')
        :flex_funds_other_details
      end

      raise "unrecognized flex funds question: #{question}" if definition_key.nil?

      values = case definition_key
      when :flex_funds_types
        answer.split('|').map { |ff_type| { value_string: flex_funds_type(ff_type) } }
      when :flex_funds_other_details
        [{ value_string: answer }]
      else
        []
      end

      definition = cde_definition(owner_type: model_class.name, key: definition_key)
      attributes = {
        data_element_definition_id: definition.id,
        owner_type: model_class.name,
        DateCreated: parse_date(row_value(row, field: 'Date Taken')),
        DateUpdated: parse_date(row_value(row, field: 'Date Taken')),
        UserID: system_user_id,
        data_source_id: data_source.id,
      }
      values.compact.map { |h| h.merge(attributes) }
    end

    # Map strings into values that match exact picklist options in the flex funds form
    # Expected list:
    # ["Cell phone", "Child care", "Food/Groceries", "Legal", "Move-in (Including first, last and security)", "Other    *If other please specify", "Transportation"]
    def flex_funds_type(str)
      return 'Other' if str.starts_with?('Other')

      str
    end

    def custom_service_type
      @custom_service_type ||= begin
        category = Hmis::Hud::CustomServiceCategory.where(
          name: 'Flex Funds',
          data_source_id: data_source.id,
        ).first_or_create!(user_id: system_user_id)
        Hmis::Hud::CustomServiceType.where(
          name: 'Flex Funds',
          custom_service_category_id: category.id,
          data_source_id: data_source.id,
        ).first_or_create!(user_id: system_user_id)
      end
    end

    def model_class
      Hmis::Hud::CustomService
    end
  end
end
