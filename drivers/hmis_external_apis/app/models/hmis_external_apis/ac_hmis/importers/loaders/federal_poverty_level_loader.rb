###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class FederalPovertyLevelLoader < CustomDataElementBaseLoader
    def filename
      'FederalPovertyLevel.csv'
    end

    protected

    def cde_definitions_keys
      [:federal_poverty_level]
    end

    def build_records
      benefit_id_lookup = owner_class
        .where(data_source: data_source)
        .pluck(:income_benefits_id, :id, :enrollment_id)
        .to_h { |income_benefits_id, pk, enrollment_id| [income_benefits_id, [pk, enrollment_id]] }
      expected = 0
      records = rows.map do |row|
        value = row_value(row, field: 'FEDERALPOVERTYLEVEL', required: false)
        next if value.nil? || value == 'Data not collected'

        expected += 1
        benefits_id = row_value(row, field: 'INCOMEBENEFITSID')
        benefit_pk, enrollment_id = benefit_id_lookup[benefits_id]

        unless benefit_pk
          log_skipped_row(row, field: 'INCOMEBENEFITSID')
          next # early return
        end

        raise 'BenefitsID/EnrollmentID mismatch' if enrollment_id != row_value(row, field: 'ENROLLMENTID')

        new_cde_record(
          value: value,
          definition_key: :federal_poverty_level,
        ).merge(owner_id: benefit_pk)
      end.compact
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def owner_class
      Hmis::Hud::IncomeBenefit
    end
  end
end
