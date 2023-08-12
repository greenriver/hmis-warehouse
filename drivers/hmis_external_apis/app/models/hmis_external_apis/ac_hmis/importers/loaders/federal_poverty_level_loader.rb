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

    def build_records
      # fixme validate that enrollment/benefit ids match and are all present
      owner_id_by_benefit_id = owner_class
        .where(data_source: data_source)
        .pluck(:income_benefits_id, :id)
        .to_h
      rows.map do |row|
        benefits_id = row_value(row, field: 'INCOMEBENEFITSID')
        new_cde_record(
          value: row_value(row, field: 'FEDERALPOVERTYLEVEL', required: false),
          definition_key: :federal_poverty_level,
        ).merge(
          owner_id: owner_id_by_benefit_id.fetch(benefits_id),
        )
      end
    end

    def owner_class
      Hmis::Hud::IncomeBenefit
    end
  end
end
