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
          fa_end_date: parse_date(row_value(row, field: 'PAYMENTENDDATE', required: false)),
          fa_amount: row_value(row, field: 'AMOUNT', required: false),
          date_created: parse_date(row_value(row, field: 'DATECREATED')),
          date_updated: parse_date(row_value(row, field: 'DATEUPDATED')),
          user_id: row_value(row, field: 'USERID', required: false) || system_user_id,
        }

        cde_attrs(row).each do |attrs|
          record.custom_data_elements.build(attrs)
        end
        record.personal_id = personal_id_by_enrollment_id.fetch(record.enrollment_id)
        record.service_type = custom_service_type
        record.date_provided = today # FIXME - this isn't right?

        record
      end
    end

    def cde_attrs(row)
      [
        [row_value(row, field: 'FUNDINGSOURCE'), :funding_source],
        [row_value(row, field: 'PAYMENTTYPE', required: false), :payment_type],
      ].map do |value, definition_key|
        next unless value

        definition = cde_definition(owner_type: model_class.name, key: definition_key)
        {
          data_element_definition_id: definition.id,
          value_string: value,
          DateCreated: parse_date(row_value(row, field: 'DATECREATED')),
          DateUpdated: parse_date(row_value(row, field: 'DATEUPDATED')),
        }.merge(default_attrs)
      end.compact
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
