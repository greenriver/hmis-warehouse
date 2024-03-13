###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CaseManagementAssessmentLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Based on the the data Gig extracted from the form definition
    CDED_CONFIGS = [
      { key: 'cma_a1_contact_type', label: 'Type of Contact', field_type: 'string', repeats: false },
      { element_id: 574, key: 'cma_a2_service_location', label: 'Service Location', field_type: 'string', repeats: false },
      { key: 'cma_a4_time_spent', label: 'Time Spent', field_type: 'integer', repeats: false },
      { element_id: 2564, key: 'cma_a5_day_night_team', label: "(Only Outreach Programs)\nDay and Night Team:", field_type: 'string', repeats: false },
      { key: 'cma_a6_diverted', label: 'Were you able to divert the client?', field_type: 'boolean', repeats: false },
      { key: 'cma_a13_case_note', label: 'Case Notes', field_type: 'string', repeats: false },
      { key: 'cma_a20_cm_checklist', label: 'Housed Client Case Management Check list', field_type: 'boolean', repeats: false },
      { key: 'cma_a30_limiting_contact', label: 'Are you limiting your contact with others?', field_type: 'boolean', repeats: false },
      { key: 'cma_a31_emotions', label: 'How are you feeling emotionally? (Overwhelmed, Stressed, Sad, Paranoid?)', field_type: 'string', repeats: false },
      { key: 'cma_a32_enjoyment',
        label: 'What have you done recently that you enjoyed? Is this something you can do on a regular basis? If not, what is something that you can do each day that you do enjoy?',
        field_type: 'string',
        repeats: false },
      { key: 'cma_a33_physical_activity', label: 'What type of physical activity are you doing and how often?', field_type: 'string', repeats: false },
      { key: 'cma_a34_leaving_house', label: 'When is the last time you left your house?', field_type: 'string', repeats: false },
      { key: 'cma_a35_social_media', label: 'Are you connecting with people over the phone or through social media?', field_type: 'string', repeats: false },
      { key: 'cma_a36_needs', label: "Is there something you are in need of because you can't get out?", field_type: 'string', repeats: false },
      { key: 'cma_a37_food', label: 'Is there adequate food? Is the household receiving food stamps? If no, is the household eligible for food stamps?', field_type: 'string', repeats: false },
      { key: 'cma_a38_afford_medical_care', label: 'Is everyone in the household able to afford medical care and prescriptions?', field_type: 'boolean', repeats: false },
      { key: 'cma_a39_medical_needs', label: 'Are there any other medical or dental needs that need to be addressed?', field_type: 'string', repeats: false },
      { key: 'cma_a40_medical_costs_plan', label: 'If you are not able to afford medical care or prescriptions, what is your plan?', field_type: 'string', repeats: false },
      { key: 'cma_a41_neighbors_landlord', label: 'Are there any issues with your neighbors or landlord? Are you aware of the restrictions enforced on landlords to not evict?', field_type: 'string', repeats: false },
      { key: 'cma_a42_neighbors_landlord_complaints',
        label: "Has our office received any complaints form the landlord or neighbors about the tenant/household? (If so, please discuss complaints and document the participant's response.)",
        field_type: 'string',
        repeats: false },
      { key: 'cma_a43_paying_rent', label: 'Have you been able to pay your rent? Are you having any difficulty in paying rent?', field_type: 'string', repeats: false },
      { key: 'cma_a44_paying_utilities', label: 'Have you been able to pay your utilities? Does the apartment/unit have all required utilities working and in service?', field_type: 'string', repeats: false },
      { key: 'cma_a45_apartment_condition',
        label: "How is the apartment looking? Are there any broken appliances or repairs that are the landlord's responsibility? (Tenant needs to call the landlord first - if repairs are not made in a timely manner, the tenant should notify the Case Manager who will then contact the landlord.)",
        field_type: 'string',
        repeats: false },
      { key: 'cma_a46_income_change', label: 'Has there been any change in the household income? If so, explain. (Rent will be recalculated ONLY if household income has decreased.)', field_type: 'string', repeats: false },
      { key: 'cma_a47_unemployment', label: 'If unemployment has occurred, can the participant apply for unemployment benefits?', field_type: 'string', repeats: false },
      { key: 'cma_a48_taxes', label: 'If you have worked in the past 2 years, have you filed your taxes?', field_type: 'string', repeats: false },
      { key: 'cma_a49_next_home_call', label: 'Date of Next Home Call:', field_type: 'date', repeats: false },
    ].freeze

    def filename
      'CMA.xlsx'
    end

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "cma-eto-#{response_id}"
    end

    def form_definition_identifier
      'case-management-note-assessment'
    end
  end
end
