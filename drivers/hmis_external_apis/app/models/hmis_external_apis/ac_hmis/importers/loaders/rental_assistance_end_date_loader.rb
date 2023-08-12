###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class RentalAssistanceEndDateLoader < CustomDataElementBaseLoader
    def filename
       'RentalAssistanceEndDate.csv'
    end

    protected

    def build_records(rows)
      # FIXME- should check that enrollment is HOH
      owner_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h
      rows.map do |row|
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        owner_id = owner_id_by_enrollment_id.fetch(enrollment_id)
        new_cde_record(
          value: rental_assistance_end_date(row),
          definition_key: :rental_assistance_end_date,
        ).merge(owner_id: owner_id)
      end
    end

    def rental_assistance_end_date(row)
      # '12/08/2021'
      value = row_value(row, field: 'RENTALASSISTANCEENDDATE')
      value ? Date.strptime(value, '%m/%d/%Y').to_s(:db) : nil
    end

    def owner_class
      Hmis::Hud::Enrollment
    end
  end
end
