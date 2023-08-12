###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
      model_class.where(data_source: data_source).destroy_all if clobber
      model_class.import(
        records,
        validate: false,
        batch_size: 1_000,
        recursive: true,
      )
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

      rows.map do |row|
        record = model_class.new(default_attrs)
        record.CustomServiceID = Hmis::Hud::Base.generate_uuid

        record.attributes = {
          enrollment_id: row_value(row, field: 'ENROLLMENTID'),
          fa_start_date: parse_date(row_value(row, field: 'PAYMENTSTARTDATE')),
          fa_end_date: parse_date(row_value(row, field: 'PAYMENTENDDATE')),
          fa_amount: row_value(row, field: 'AMOUNT'),
          date_created: parse_date(row_value(row, field: 'DATECREATED')),
          date_updated: parse_date(row_value(row, field: 'DATEUPDATED')),
          user_id: row_value(row, field: 'USERID') || system_user_id,
        }

        record.custom_data_elements = build_cdes(row)
        record.personal_id = personal_id_by_enrollment_id.fetch(record.enrollment_id)
        record.service_type = custom_service_type
        record.date_provided = today # FIXME - this isn't right?

        record
      end
    end

    def build_cdes(row)
      [
        ['FUNDINGSOURCE', :funding_source],
        ['PAYMENTTYPE', :payment_type],
      ].map do |field, definition_key|
        value = row_value(row, field: field)
        definition = cde_definition(owner_type: model_class.name, key: definition_key)
        attrs = {
          owner_type: model_class.name,
          data_element_definition_id: definition.id,
          date_created: parse_date(row_value(row, field: 'DATECREATED')),
          date_updated: parse_date(row_value(row, field: 'DATEUPDATED')),
          value_string: value,
        }.merge(default_attrs)
        Hmis::Hud::CustomDataElement.new(attrs)
      end
    end

    def custom_service_type
      @custom_service_type ||= begin
        category = Hmis::Hud::CustomServiceCategory.where(
          name: 'ESG Funding Assistance',
          data_source_id: data_source.id
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
