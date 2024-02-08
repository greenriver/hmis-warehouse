###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
# creates CustomService and CustomDataElements
module HmisExternalApis::AcHmis::Importers::Loaders
  class EsgFundingAssistanceLoader < SingleFileLoader
    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).each(&:really_destroy!) if clobber

      # can't do bulk insert here since polymorphic CDE's don't seem to work
      # and bulk-insert returned ids are not ordered
      without_paper_trail do
        records.each { |record| record.save!(validate: false) }
      end
      Rails.logger.info "#{self.class.name} inserted: #{records.size} records into #{model_class.table_name}"
    end

    protected

    def filename
      'ESGFundingAssistance.csv'
    end

    def build_records
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :personal_id)
        .to_h

      expected = 0
      records = rows.map do |row|
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        personal_id = personal_id_by_enrollment_id[enrollment_id]
        expected += 1
        unless personal_id
          log_skipped_row(row, field: 'ENROLLMENTID')
          next # early return
        end

        start_date = parse_date(row_value(row, field: 'PAYMENTSTARTDATE'))
        record = model_class.new(
          EnrollmentID: enrollment_id,
          CustomServiceID: Hmis::Hud::Base.generate_uuid,
          FAStartDate: start_date,
          FAEndDate: parse_date(row_value(row, field: 'PAYMENTENDDATE', required: false)),
          FAAmount: row_value(row, field: 'AMOUNT', required: false),
          DateCreated: parse_date(row_value(row, field: 'DATECREATED')),
          DateUpdated: parse_date(row_value(row, field: 'DATEUPDATED')),
          custom_service_type_id: custom_service_type.id,
          PersonalID: personal_id,
          DateProvided: start_date, # re-use payment start date
          UserID: row_value(row, field: 'USERID', required: false) || system_user_id,
          data_source_id: data_source.id,
        )
        cde_attrs(row).each do |attr|
          record.custom_data_elements.build(attr)
        end
        record
      end.compact
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def cde_attrs(row)
      [
        # funding source is supposed to be required but data has missing values
        [funding_source(row), :funding_source],
        [row_value(row, field: 'PAYMENTTYPE', required: false), :payment_type],
      ].map do |value, definition_key|
        next unless value

        definition = cde_definition(owner_type: model_class.name, key: definition_key)
        {
          owner_type: model_class.name,
          data_element_definition_id: definition.id,
          value_string: value,
          DateCreated: parse_date(row_value(row, field: 'DATECREATED')),
          DateUpdated: parse_date(row_value(row, field: 'DATEUPDATED')),
          UserID: row_value(row, field: 'USERID', required: false) || system_user_id,
          data_source_id: data_source.id,
        }
      end.compact
    end

    FUNDING_SOURCE_MAP = {
      '**Allegheny County**' => 'Allegheny County ESG',
      '**City of Pittsburgh**' => 'City of Pittsburgh ESG',
      '**State of Pennsylvania**' => 'State of Pennsylvania ESG',
    }.freeze
    def funding_source(row)
      value = row_value(row, field: 'FUNDINGSOURCE', required: false)
      FUNDING_SOURCE_MAP[value] || value
    end

    def custom_service_type
      @custom_service_type ||= begin
        category = Hmis::Hud::CustomServiceCategory.where(
          name: 'ESG Funding Assistance',
          data_source_id: data_source.id,
        ).first_or_create!(user_id: system_user_id)
        Hmis::Hud::CustomServiceType.where(
          name: 'ESG Funding Assistance',
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
