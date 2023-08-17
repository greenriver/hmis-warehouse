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
      rows.map do |row|
        benefits_id = row_value(row, field: 'INCOMEBENEFITSID')
        benefit_pk, enrollment_id = benefit_id_lookup.fetch(benefits_id)
        raise 'BenefitsID/EnrollmentID mismatch' if enrollment_id != row_value(row, field: 'ENROLLMENTID')

        new_cde_record(
          value: row_value(row, field: 'FEDERALPOVERTYLEVEL', required: false),
          definition_key: :federal_poverty_level,
        ).merge(owner_id: benefit_pk)
      end
    end

    def owner_class
      Hmis::Hud::IncomeBenefit
    end
  end
end
