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

    def cde_definitions_keys
      [:rental_assistance_end_date]
    end

    def build_records
      owner_id_by_enrollment_id = Hmis::Hud::Enrollment
        # .heads_of_households # enrollments should HOH but many are not
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h
      expected = 0
      records = rows.map do |row|
        expected += 1
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        owner_id = owner_id_by_enrollment_id[enrollment_id]
        unless owner_id
          log_skipped_row(row, field: 'ENROLLMENTID')
          next # early return
        end
        new_cde_record(
          value: parse_date(row_value(row, field: 'RENTALASSISTANCEENDDATE')),
          definition_key: :rental_assistance_end_date,
        ).merge(owner_id: owner_id)
      end
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def owner_class
      Hmis::Hud::Enrollment
    end
  end
end
