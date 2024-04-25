###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class DcsfV3Loader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    def filename
      'DCSF_V3.xlsx'
    end

    CDED_CONFIGS = [
      { element_id: 8565, key: 'agency_name', repeats: false, field_type: 'string' },
      { element_id: 8264, key: 'funding_type', repeats: false, field_type: 'string' },
      { element_id: 7540, key: 'funding_categories', repeats: false, field_type: 'string' },
      { element_id: 9225, key: 'document_type', repeats: false, field_type: 'string' },
      { element_id: 8356, key: 'rrh_or_psh', repeats: false, field_type: 'boolean' },
      { element_id: 8257, key: 'admin_app_fee', repeats: false, field_type: 'float' },
      { element_id: 8258, key: 'high_risk_opportunity_fee', repeats: false, field_type: 'float' },
      { element_id: 8259, key: 'deposit', repeats: false, field_type: 'float' },
      { element_id: 8260, key: 'pet_deposit', repeats: false, field_type: 'float' },
      { element_id: 8262, key: 'damages', repeats: false, field_type: 'float' },
      { element_id: 8263, key: 'utility_deposit', repeats: false, field_type: 'float' },
      { element_id: 8486, key: 'household_type', repeats: false, field_type: 'string' },
      { element_id: 8268, key: 'bus_or_transportation', repeats: false, field_type: 'float' },
      { element_id: 8264, key: 'rent_one_time_assistance', repeats: false, field_type: 'float' },
      { element_id: 8268, key: 'family_motel', repeats: false, field_type: 'float' },
      { element_id: 13230, key: 'family_day_sheltering', repeats: false, field_type: 'float' },
      { element_id: 8603, key: 'additional_furniture_mattress', repeats: false, field_type: 'float' },
      { element_id: 9217, key: 'drivers_license_state_id', repeats: false, field_type: 'float' },
      { element_id: 9218, key: 'birth_certificate', repeats: false, field_type: 'float' },
      { element_id: 9219, key: 'social_security_card', repeats: false, field_type: 'float' },
      { element_id: 9220, key: 'marriage_death_certificate', repeats: false, field_type: 'float' },
      { element_id: 9227, key: 'housing_search_transportation', repeats: false, field_type: 'float' },
      { element_id: 7551, key: 'date_payment_made', repeats: false, field_type: 'date' },
      { element_id: 7546, key: 'payment_amount', repeats: false, field_type: 'float' },
      { element_id: 10370, key: 'name_of_apartment_complex_property_owner', repeats: false, field_type: 'string' },
      { element_id: 7552, key: 'other_efforts', repeats: false, field_type: 'string' },
      { element_id: 7543, key: 'reason_for_denial', repeats: false, field_type: 'string' },
      { element_id: 7541 , key: 'status', repeats: false, field_type: 'string' },
      { element_id: 7545, key: 'reason_for_pending_status', repeats: false, field_type: 'string' },
      { element_id: 8604, key: 'approved_date', repeats: false, field_type: 'date' },
      { element_id: 8690, key: 'final_funding_category', repeats: false, field_type: 'string' },
      { element_id: 7539, key: 'funding_source', repeats: false, field_type: 'string' },
    ].freeze

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "dcsf_v3-eto-#{response_id}"
    end

    def form_definition_identifier
      'dcsf_v3'
    end
  end
end
