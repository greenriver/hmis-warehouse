###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::FundingSource < Types::BaseEnum
    description '2.6.1'
    graphql_name 'FundingSource'
    value 'HUD_COC_HOMELESSNESS_PREVENTION_HIGH_PERFORMING_COMMUNITIES_ONLY', '(1) HUD: CoC - Homelessness Prevention (High Performing Communities Only)', value: 1
    value 'HUD_COC_PERMANENT_SUPPORTIVE_HOUSING', '(2) HUD: CoC - Permanent Supportive Housing', value: 2
    value 'HUD_COC_RAPID_RE_HOUSING', '(3) HUD: CoC - Rapid Re-Housing', value: 3
    value 'HUD_COC_SUPPORTIVE_SERVICES_ONLY', '(4) HUD: CoC - Supportive Services Only', value: 4
    value 'HUD_COC_TRANSITIONAL_HOUSING', '(5) HUD: CoC - Transitional Housing', value: 5
    value 'HUD_COC_SAFE_HAVEN', '(6) HUD: CoC - Safe Haven', value: 6
    value 'HUD_COC_SINGLE_ROOM_OCCUPANCY_SRO', '(7) HUD: CoC - Single Room Occupancy (SRO)', value: 7
    value 'HUD_ESG_EMERGENCY_SHELTER_OPERATING_AND_OR_ESSENTIAL_SERVICES', '(8) HUD: ESG - Emergency Shelter (operating and/or essential services)', value: 8
    value 'HUD_ESG_HOMELESSNESS_PREVENTION', '(9) HUD: ESG - Homelessness Prevention ', value: 9
    value 'HUD_ESG_RAPID_REHOUSING', '(10) HUD: ESG - Rapid Rehousing', value: 10
    value 'HUD_ESG_STREET_OUTREACH', '(11) HUD: ESG - Street Outreach', value: 11
    value 'HUD_RURAL_HOUSING_STABILITY_ASSISTANCE_PROGRAM', '(12) HUD: Rural Housing Stability Assistance Program ', value: 12
    value 'HUD_HOPWA_HOTEL_MOTEL_VOUCHERS', '(13) HUD: HOPWA - Hotel/Motel Vouchers', value: 13
    value 'HUD_HOPWA_HOUSING_INFORMATION', '(14) HUD: HOPWA - Housing Information', value: 14
    value 'HUD_HOPWA_PERMANENT_HOUSING_FACILITY_BASED_OR_TBRA', '(15) HUD: HOPWA - Permanent Housing (facility based or TBRA)', value: 15
    value 'HUD_HOPWA_PERMANENT_HOUSING_PLACEMENT', '(16) HUD: HOPWA - Permanent Housing Placement', value: 16
    value 'HUD_HOPWA_SHORT_TERM_RENT_MORTGAGE_UTILITY_ASSISTANCE', '(17) HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance', value: 17
    value 'HUD_HOPWA_SHORT_TERM_SUPPORTIVE_FACILITY', '(18) HUD: HOPWA - Short-Term Supportive Facility', value: 18
    value 'HUD_HOPWA_TRANSITIONAL_HOUSING_FACILITY_BASED_OR_TBRA', '(19) HUD: HOPWA - Transitional Housing (facility based or TBRA)', value: 19
    value 'HUD_HUD_VASH', '(20) HUD: HUD/VASH', value: 20
    value 'HHS_PATH_STREET_OUTREACH_SUPPORTIVE_SERVICES_ONLY', '(21) HHS: PATH - Street Outreach & Supportive Services Only', value: 21
    value 'HHS_RHY_BASIC_CENTER_PROGRAM_PREVENTION_AND_SHELTER', '(22) HHS: RHY - Basic Center Program (prevention and shelter)', value: 22
    value 'HHS_RHY_MATERNITY_GROUP_HOME_FOR_PREGNANT_AND_PARENTING_YOUTH', '(23) HHS: RHY - Maternity Group Home for Pregnant and Parenting Youth', value: 23
    value 'HHS_RHY_TRANSITIONAL_LIVING_PROGRAM', '(24) HHS: RHY - Transitional Living Program', value: 24
    value 'HHS_RHY_STREET_OUTREACH_PROJECT', '(25) HHS: RHY - Street Outreach Project', value: 25
    value 'HHS_RHY_DEMONSTRATION_PROJECT', '(26) HHS: RHY - Demonstration Project', value: 26
    value 'VA_CRS_CONTRACT_RESIDENTIAL_SERVICES', '(27) VA: CRS Contract Residential Services', value: 27
    value 'VA_COMMUNITY_CONTRACT_SAFE_HAVEN_PROGRAM', '(30) VA: Community Contract Safe Haven Program', value: 30
    value 'VA_COMPENSATED_WORK_THERAPY_TRANSITIONAL_RESIDENCE', '(32) VA: Compensated Work Therapy Transitional Residence', value: 32
    value 'VA_SUPPORTIVE_SERVICES_FOR_VETERAN_FAMILIES', '(33) VA: Supportive Services for Veteran Families', value: 33
    value 'N_A', '(34) N/A', value: 34
    value 'HUD_PAY_FOR_SUCCESS', '(35) HUD: Pay for Success', value: 35
    value 'HUD_PUBLIC_AND_INDIAN_HOUSING_PIH_PROGRAMS', '(36) HUD: Public and Indian Housing (PIH) Programs', value: 36
    value 'VA_GRANT_PER_DIEM_BRIDGE_HOUSING', '(37) VA: Grant Per Diem - Bridge Housing', value: 37
    value 'VA_GRANT_PER_DIEM_LOW_DEMAND', '(38) VA: Grant Per Diem - Low Demand', value: 38
    value 'VA_GRANT_PER_DIEM_HOSPITAL_TO_HOUSING', '(39) VA: Grant Per Diem - Hospital to Housing', value: 39
    value 'VA_GRANT_PER_DIEM_CLINICAL_TREATMENT', '(40) VA: Grant Per Diem - Clinical Treatment', value: 40
    value 'VA_GRANT_PER_DIEM_SERVICE_INTENSIVE_TRANSITIONAL_HOUSING', '(41) VA: Grant Per Diem - Service Intensive Transitional Housing', value: 41
    value 'VA_GRANT_PER_DIEM_TRANSITION_IN_PLACE', '(42) VA: Grant Per Diem - Transition in Place', value: 42
    value 'HUD_COC_YOUTH_HOMELESS_DEMONSTRATION_PROGRAM_YHDP', '(43) HUD: CoC - Youth Homeless Demonstration Program (YHDP)', value: 43
    value 'HUD_COC_JOINT_COMPONENT_TH_RRH', '(44) HUD: CoC - Joint Component TH/RRH', value: 44
    value 'VA_GRANT_PER_DIEM_CASE_MANAGEMENT_HOUSING_RETENTION', '(45) VA: Grant Per Diem - Case Management/Housing Retention', value: 45
    value 'LOCAL_OR_OTHER_FUNDING_SOURCE', '(46) Local or Other Funding Source', value: 46
    value 'HUD_ESG_CV', '(47) HUD: ESG - CV', value: 47
    value 'HUD_HOPWA_CV', '(48) HUD: HOPWA - CV', value: 48
    value 'HUD_COC_JOINT_COMPONENT_RRH_PSH', '(49) HUD: CoC - Joint Component RRH/PSH ', value: 49
    value 'HUD_HOME', '(50) HUD: HOME', value: 50
    value 'HUD_HOME_ARP', '(51) HUD: HOME (ARP)', value: 51
    value 'HUD_PIH_EMERGENCY_HOUSING_VOUCHER', '(52) HUD: PIH (Emergency Housing Voucher)', value: 52
    value 'HUD_ESG_RUSH', '(53) HUD: ESG - RUSH', value: 53
  end
end
