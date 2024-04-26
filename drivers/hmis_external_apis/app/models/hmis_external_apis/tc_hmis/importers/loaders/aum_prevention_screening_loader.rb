###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class AumPreventionScreeningLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    def filename
      'AumPrevention.xlsx'
    end

    CDED_CONFIGS = [
      { label: 'Do you live within Arlington city limits?', key: 'within_arlington', repeats: false, field_type: 'boolean' },
      { label: 'Do you receive Section 8 or other housing subsidy?', key: 'section_8', repeats: false, field_type: 'boolean' },
      { label: 'What size apartment do you have?', key: 'apartment_size', repeats: false, field_type: 'string' },
      { label: 'Is your rent less that $1,064 for one bedroom?', key: 'rent_less_than_x_one_bedroom', repeats: false, field_type: 'boolean' },
      { label: 'Is your rent less thatn $1,269 for a two bedroom?', key: 'rent_less_than_x_two_bedroom', repeats: false, field_type: 'boolean' },
      { label: 'Is your rent less than $1,685 for a three bedroom?', key: 'rent_less_than_x_three_bedroom', repeats: false, field_type: 'boolean' },
      { label: 'Is your rent less than $2,098 for a four bedroom?', key: 'rent_less_than_x_four_bedroom', repeats: false, field_type: 'boolean' },
      { label: 'Is your income less than 30% of the Area Median Income? (see chart below)', key: 'income_less_than_30_percent', repeats: false, field_type: 'boolean' },
      { label: 'Have you ever been literally homeless (staying in a Homeless Shelter, Outside, or other place not meant for habitation)?', key: 'literally_homeless', repeats: false, field_type: 'boolean' },
      { label: 'Have you received either a "Notice to Vacate" or an "Eviction Notice"?', key: 'notice_vacate_or_eviction', repeats: false, field_type: 'boolean' },
      { label: 'How many people are in the household?', key: 'household_size', repeats: false, field_type: 'integer' },
      { label: "Do all adults in the household have a State ID or Driver's License?", key: 'state_id_drivers_license', repeats: false, field_type: 'boolean' },
      { label: 'Does EVERYONE in the household have a social security card and birth certificate?', key: 'section_social_security_birth_cert', repeats: false, field_type: 'boolean' },
      { label: 'What is the ANNUAL household income?', key: 'annual_household_income', repeats: false, field_type: 'integer' },
      { label: 'What is the source of the household income (i.e. full time job, part-time job, SSI, SDI, etc.)?', key: 'source_of_income', repeats: false, field_type: 'string' },
      { label: 'How much is your monthly base rent (rent only)?', key: 'base_rent', repeats: false, field_type: 'integer' },
    ].freeze

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "aum_prevention-eto-#{response_id}"
    end

    def form_definition_identifier
      'aum_prevention'
    end

    def cde_values(row, config)
      cded_key = config.fetch(:key)
      values = super(row, config)
      if cded_key =~ /household_size/
        values.map do |value|
          # garbage values cause out of range errors
          value > 100 ? nil : value
        end
      else
        values
      end
    end
  end
end
