###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class FederalPovertyLevelLoader < BaseLoader
    #def validate_rows(rows)
      # fixme validate that enrollment/benefit ids match and are all present
      # rows.each do |row|
      #  cols.each do |col|
      #    col.validate(row)
      #  end
      # end
    #end

    def perform(rows:)
      owner_id_by_benefit_id = owner_class
        .where(data_source: data_source)
        .pluck(:income_benefits_id, :id)
        .to_h

      records = rows.map do |row|
        record = model_class.new(default_attrs)
        benefit_id = row_value(row, field: 'IncomeBenefitsID')
        record.owner_type = owner_class.name
        record.owner_id = owner_id_by_benefit_id.fetch(benefit_id)
        record.data_element_definition = definition
        record.value_string = row_value(row, field: 'FederalPovertyLevel')
        record
      end

      # destroy existing records and re-import
      model_class
        .where(data_source: data_source)
        .where(owner_type: owner_class.name)
        .destroy_all
      model_class.import(
        records,
        validate: false,
        batch_size: 1_000,
      )
    end

    protected

    def model_class
      Hmis::Hud::CustomDataElement
    end

    def owner_class
      Hmis::Hud::IncomeBenefit
    end

    def definition
      @definition ||= Hmis::Hud::CustomDataElementDefinition
        .where(
          owner_type: model_class.name,
          field_type: :string,
          key: :federal_poverty_level,
          label: 'Federal Poverty Level',
          data_source_id: data_source_id,
        ).first_or_create!(user: user)
    end

    # def columns
    #   [
    #     attr_col('EnrollmentID'),
    #     attr_col('IncomeBenefitsID'),
    #     cde_col('FederalPovertyLevel')
    #   ]
    # end
  end
end
