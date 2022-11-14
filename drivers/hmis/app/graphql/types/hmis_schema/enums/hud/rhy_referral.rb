###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::RHYReferral < Types::BaseEnum
    description 'R14.2'
    graphql_name 'RHYReferral'
    value CHILD_CARE_NON_TANF, '(1) Child care non-TANF', value: 1
    value SUPPLEMENTAL_NUTRITIONAL_ASSISTANCE_PROGRAM_FOOD_STAMPS, '(2) Supplemental nutritional assistance program (food stamps)', value: 2
    value EDUCATION_MC_KINNEY_VENTO_LIAISON_ASSISTANCE_TO_REMAIN_IN_SCHOOL, '(3) Education - McKinney/Vento liaison assistance to remain in school', value: 3
    value HUD_SECTION_8_OR_OTHER_PERMANENT_HOUSING_ASSISTANCE, '(4) HUD section 8 or other permanent housing assistance', value: 4
    value INDIVIDUAL_DEVELOPMENT_ACCOUNT, '(5) Individual development account', value: 5
    value MEDICAID, '(6) Medicaid', value: 6
    value MENTORING_PROGRAM_OTHER_THAN_RHY_AGENCY, '(7) Mentoring program other than RHY agency', value: 7
    value NATIONAL_SERVICE_AMERICORPS_VISTA_LEARN_AND_SERVE, '(8) National service (Americorps, VISTA, Learn and Serve)', value: 8
    value NON_RESIDENTIAL_SUBSTANCE_ABUSE_OR_MENTAL_HEALTH_PROGRAM, '(9) Non-residential substance abuse or mental health program', value: 9
    value OTHER_PUBLIC_FEDERAL_STATE_OR_LOCAL_PROGRAM, '(10) Other public - federal, state, or local program', value: 10
    value PRIVATE_NON_PROFIT_CHARITY_OR_FOUNDATION_SUPPORT, '(11) Private non-profit charity or foundation support', value: 11
    value SCHIP, '(12) SCHIP', value: 12
    value SSI_SSDI_OR_OTHER_DISABILITY_INSURANCE, '(13) SSI, SSDI, or other disability insurance', value: 13
    value TANF_OR_OTHER_WELFARE_NON_DISABILITY_INCOME_MAINTENANCE_ALL_TANF_SERVICES, '(14) TANF or other welfare/non-disability income maintenance (all TANF services)', value: 14
    value UNEMPLOYMENT_INSURANCE, '(15) Unemployment insurance', value: 15
    value WIC, '(16) WIC', value: 16
    value WORKFORCE_DEVELOPMENT_WIA, '(17) Workforce development (WIA)', value: 17
  end
end
