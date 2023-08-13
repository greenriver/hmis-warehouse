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
      result = model_class.import(
        records,
        validate: false,
        batch_size: 1_000,
        # recursive: true, doesn't work for some reason, probably because CDE relationship is polymorphic
        returning: :id,
      )
      return result if result.failed_instances.present?

      import_cdes(result.ids)
    end

    protected

    def import_cdes(ids)
      records = rows.flat_map.with_index do |row, idx|
        owner_id = ids[idx]
        results = cde_attrs(row)
        results.each { |attr| attr[:owner_id] = owner_id }
        results
      end
      Hmis::Hud::CustomDataElement.import(records, validate: false, batch_size: 1_000)
    end

    def filename
      'ESGFundingAssistance.csv'
    end

    def build_records
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :personal_id)
        .to_h

      rows.map do |row|
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        {
          EnrollmentID: enrollment_id,
          CustomServiceID: Hmis::Hud::Base.generate_uuid,
          FAStartDate: parse_date(row_value(row, field: 'PAYMENTSTARTDATE')),
          FAEndDate: parse_date(row_value(row, field: 'PAYMENTENDDATE', required: false)),
          FAAmount: row_value(row, field: 'AMOUNT', required: false),
          DateCreated: parse_date(row_value(row, field: 'DATECREATED')),
          DateUpdated: parse_date(row_value(row, field: 'DATEUPDATED')),
          custom_service_type_id: custom_service_type.id,
          PersonalID: personal_id_by_enrollment_id.fetch(enrollment_id),
          DateProvided: today, # FIXME - this isn't right?
          UserID: row_value(row, field: 'USERID', required: false) || system_user_id,
          data_source_id: data_source.id,
        }
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
