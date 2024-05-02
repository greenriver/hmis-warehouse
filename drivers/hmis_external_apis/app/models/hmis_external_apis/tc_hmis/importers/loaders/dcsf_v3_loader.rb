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
      { label: 'Funding Source', key: 'funding_source', repeats: false, field_type: 'string' },
      { label: 'Funding Categories', key: 'funding_categories', repeats: false, field_type: 'string' },
      { label: 'Status', key: 'status', repeats: false, field_type: 'string' },
      { label: 'Reason For denial', key: 'reason_for_denial', repeats: false, field_type: 'string' },
      { label: 'Reason For Pending Status.', key: 'reason_for_pending_status', repeats: false, field_type: 'string' },
      { label: 'Payment Amount.', key: 'payment_amount', repeats: false, field_type: 'float' },
      { label: 'Date payment was made', key: 'date_payment_made', repeats: false, field_type: 'date' },
      { label: 'What efforts have been made to secure funds other than DCSF?', key: 'other_efforts', repeats: false, field_type: 'string' },
      { label: 'Administration/application fee', key: 'admin_app_fee', repeats: false, field_type: 'float' },
      { label: 'High Risk/Opportunity fee', key: 'high_risk_opportunity_fee', repeats: false, field_type: 'float' },
      { label: 'Deposit', key: 'deposit', repeats: false, field_type: 'float' },
      { label: 'Pet Deposit', key: 'pet_deposit', repeats: false, field_type: 'float' },
      { label: 'Damages', key: 'damages', repeats: false, field_type: 'float' },
      { label: 'Utility Deposit', key: 'utility_deposit', repeats: false, field_type: 'float' },
      { label: 'Rent (one-time assistance)', key: 'rent_one_time_assistance', repeats: false, field_type: 'float' },
      { label: 'Funding TYPE', key: 'funding_type', repeats: false, field_type: 'string' },
      { label: 'Family Motel', key: 'family_motel', repeats: false, field_type: 'float' },
      { label: 'Bus Ticket or Transportation for Diversion Only', key: 'bus_or_transportation', repeats: false, field_type: 'float' },
      { label: 'Is client in a Rapid Rehousing or PSH Program?', key: 'rrh_or_psh', repeats: false, field_type: 'boolean' },
      { label: 'Household Type', key: 'household_type', repeats: false, field_type: 'string' },
      { label: 'Agency Name', key: 'agency_name', repeats: false, field_type: 'string' },
      { label: 'Additional (furniture/mattress)', key: 'additional_furniture_mattress', repeats: false, field_type: 'float' },
      { label: 'Approved Date', key: 'approved_date', repeats: false, field_type: 'date' },
      { label: 'Final Funding Category (based on information received)', key: 'final_funding_category', repeats: false, field_type: 'string' },
      { label: "Driver's License/State ID", key: 'drivers_license_state_id', repeats: false, field_type: 'float' },
      { label: 'Birth Certificate', key: 'birth_certificate', repeats: false, field_type: 'float' },
      { label: 'Social Security Card', key: 'social_security_card', repeats: false, field_type: 'float' },
      { label: 'Marriage/Death Certificate', key: 'marriage_death_certificate', repeats: false, field_type: 'float' },
      { label: 'Which type of critical document is being requested?', key: 'document_type', repeats: false, field_type: 'string' },
      { label: 'Housing Search Transportation', key: 'housing_search_transportation', repeats: false, field_type: 'float' },
      { label: 'Name of Apartment Complex/Property Owner', key: 'name_of_apartment_complex_property_owner', repeats: false, field_type: 'string' },
      { label: 'Family day sheltering', key: 'family_day_sheltering', repeats: false, field_type: 'string' },
    ].map { |h| h.merge(key: "dcsf_v3_#{h[:key]}") }.freeze

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "dcsf-v3-eto-#{response_id}"
    end

    def form_definition_identifier
      'dcsf-v3'
    end
  end
end
