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
      { element_id: 8984, key: 'within_arlington', repeats: false, field_type: 'boolean' },
      { element_id: 8985, key: 'section_8', repeats: false, field_type: 'boolean' },
      { element_id: 12257, key: 'notice_vacate_or_eviction', repeats: false, field_type: 'boolean' },
      { element_id: 12258, key: 'household_size', repeats: false, field_type: 'integer' },
      { element_id: 12259, key: 'state_id_drivers_license', repeats: false, field_type: 'boolean' },
      { element_id: 12260, key: 'section_social_security_birth_cert', repeats: false, field_type: 'boolean' },
      # check this, should be string? May need to adjust for pick list
      { element_id: 8986, key: 'apartment_size', repeats: false, field_type: 'string' },
      { element_id: 12263, key: 'base_rent', repeats: false, field_type: 'integer' },
      { element_id: 8987, key: 'rent_less_than_x_one_bedroom', repeats: false, field_type: 'boolean' },
      { element_id: 8988, key: 'rent_less_than_x_two_bedroom', repeats: false, field_type: 'boolean' },
      { element_id: 8989, key: 'rent_less_than_x_three_bedroom', repeats: false, field_type: 'boolean' },
      { element_id: 8990, key: 'rent_less_than_x_four_bedroom', repeats: false, field_type: 'boolean' },
      { element_id: 12261, key: 'annual_household_income', repeats: false, field_type: 'integer' },
      { element_id: 12262, key: 'source_of_income', repeats: false, field_type: 'string' },
      { element_id: 8991, key: 'income_less_than_30_percent', repeats: false, field_type: 'boolean' },
      { element_id: 9007, key: 'literally_homeless', repeats: false, field_type: 'boolean' },
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
