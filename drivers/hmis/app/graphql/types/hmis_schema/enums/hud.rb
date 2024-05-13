###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types::HmisSchema::Enums::Hud
  class ExportPeriodType < Types::BaseEnum
    description 'HUD ExportPeriodType (1.1)'
    graphql_name 'ExportPeriodType'
    value 'UPDATED', '(1) Updated', value: 1
    value 'REPORTING_PERIOD', '(3) Reporting period', value: 3
    value 'OTHER', '(4) Other', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ExportDirective < Types::BaseEnum
    description 'HUD ExportDirective (1.2)'
    graphql_name 'ExportDirective'
    value 'DELTA_REFRESH', '(1) Delta refresh', value: 1
    value 'FULL_REFRESH', '(2) Full refresh', value: 2
    value 'OTHER', '(3) Other', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class DisabilityType < Types::BaseEnum
    description 'HUD DisabilityType (1.3)'
    graphql_name 'DisabilityType'
    value 'PHYSICAL_DISABILITY', '(5) Physical disability', value: 5
    value 'DEVELOPMENTAL_DISABILITY', '(6) Developmental disability', value: 6
    value 'CHRONIC_HEALTH_CONDITION', '(7) Chronic health condition', value: 7
    value 'HIV_AIDS', '(8) HIV/AIDS', value: 8
    value 'MENTAL_HEALTH_DISORDER', '(9) Mental health disorder', value: 9
    value 'SUBSTANCE_USE_DISORDER', '(10) Substance use disorder', value: 10
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class RecordType < Types::BaseEnum
    description 'HUD RecordType (1.4)'
    graphql_name 'RecordType'
    value 'PATH_SERVICE', '(141) PATH Service', value: 141
    value 'RHY_SERVICE_CONNECTIONS', '(142) RHY Service Connections', value: 142
    value 'HOPWA_SERVICE', '(143) HOPWA Service', value: 143
    value 'SSVF_SERVICE', '(144) SSVF Service', value: 144
    value 'HOPWA_FINANCIAL_ASSISTANCE', '(151) HOPWA Financial Assistance', value: 151
    value 'SSVF_FINANCIAL_ASSISTANCE', '(152) SSVF Financial Assistance', value: 152
    value 'PATH_REFERRAL', '(161) PATH Referral', value: 161
    value 'BED_NIGHT', '(200) Bed Night', value: 200
    value 'HUD_VASH_OTH_VOUCHER_TRACKING', '(210) HUD-VASH OTH Voucher Tracking', value: 210
    value 'MOVING_ON_ASSISTANCE', '(300) Moving On Assistance', value: 300
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HashStatus < Types::BaseEnum
    description 'HUD HashStatus (1.5)'
    graphql_name 'HashStatus'
    value 'UNHASHED', '(1) Unhashed', value: 1
    value 'SHA_1_RHY', '(2) SHA-1 RHY', value: 2
    value 'HASHED_OTHER', '(3) Hashed - other', value: 3
    value 'SHA_256_RHY', '(4) SHA-256 (RHY)', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NoYesMissing < Types::BaseEnum
    description 'HUD NoYesMissing (1.7)'
    graphql_name 'NoYesMissing'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NoYesReasonsForMissingData < Types::BaseEnum
    description 'HUD NoYesReasonsForMissingData (1.8)'
    graphql_name 'NoYesReasonsForMissingData'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SourceType < Types::BaseEnum
    description 'HUD SourceType (1.9)'
    graphql_name 'SourceType'
    value 'COC_HMIS', '(1) CoC HMIS', value: 1
    value 'STANDALONE_AGENCY_SPECIFIC_APPLICATION', '(2) Standalone/agency-specific application', value: 2
    value 'DATA_WAREHOUSE', '(3) Data warehouse', value: 3
    value 'OTHER', '(4) Other', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NoYes < Types::BaseEnum
    description 'HUD NoYes (1.10)'
    graphql_name 'NoYes'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class TargetPopulation < Types::BaseEnum
    description 'HUD TargetPopulation (2.02.7)'
    graphql_name 'TargetPopulation'
    value 'DV_SURVIVOR_OF_DOMESTIC_VIOLENCE', '(1) DV: Survivor of Domestic Violence', value: 1
    value 'HIV_PERSONS_WITH_HIV_AIDS', '(3) HIV: Persons with HIV/AIDS', value: 3
    value 'NA_NOT_APPLICABLE', '(4) NA: Not applicable', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HOPWAMedAssistedLivingFac < Types::BaseEnum
    description 'HUD HOPWAMedAssistedLivingFac (2.02.8)'
    graphql_name 'HOPWAMedAssistedLivingFac'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'NON_HOPWA_FUNDED_PROJECT', '(2) Non-HOPWA Funded Project', value: 2
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HousingType < Types::BaseEnum
    description 'HUD HousingType (2.02.D)'
    graphql_name 'HousingType'
    value 'SITE_BASED_SINGLE_SITE', '(1) Site-based - single site', value: 1
    value 'SITE_BASED_CLUSTERED_MULTIPLE_SITES', '(2) Site-based - clustered / multiple sites', value: 2
    value 'TENANT_BASED_SCATTERED_SITE', '(3) Tenant-based - scattered site', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ProjectType < Types::BaseEnum
    description 'HUD ProjectType (2.02.6)'
    graphql_name 'ProjectType'
    value 'EMERGENCY_SHELTER_ENTRY_EXIT', '(0) Emergency Shelter - Entry Exit', value: 0
    value 'EMERGENCY_SHELTER_NIGHT_BY_NIGHT', '(1) Emergency Shelter - Night-by-Night', value: 1
    value 'TRANSITIONAL_HOUSING', '(2) Transitional Housing', value: 2
    value 'PH_PERMANENT_SUPPORTIVE_HOUSING', '(3) PH - Permanent Supportive Housing', value: 3
    value 'STREET_OUTREACH', '(4) Street Outreach', value: 4
    value 'SERVICES_ONLY', '(6) Services Only', value: 6
    value 'SAFE_HAVEN', '(8) Safe Haven', value: 8
    value 'PH_HOUSING_ONLY', '(9) PH - Housing Only', value: 9
    value 'OTHER', '(7) Other', value: 7
    value 'PH_HOUSING_WITH_SERVICES', '(10) PH - Housing with Services (no disability required for entry)', value: 10
    value 'DAY_SHELTER', '(11) Day Shelter', value: 11
    value 'HOMELESSNESS_PREVENTION', '(12) Homelessness Prevention', value: 12
    value 'PH_RAPID_RE_HOUSING', '(13) PH - Rapid Re-Housing', value: 13
    value 'COORDINATED_ENTRY', '(14) Coordinated Entry', value: 14
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ProjectTypeBrief < Types::BaseEnum
    description 'HUD ProjectTypeBrief (2.02.6.brief)'
    graphql_name 'ProjectTypeBrief'
    value 'ES_ENTRY_EXIT', '(0) ES - Entry/Exit', value: 0
    value 'ES_NBN', '(1) ES - NBN', value: 1
    value 'TH', '(2) TH', value: 2
    value 'PH_PSH', '(3) PH - PSH', value: 3
    value 'SO', '(4) SO', value: 4
    value 'SSO', '(6) SSO', value: 6
    value 'SH', '(8) SH', value: 8
    value 'PH_PH', '(9) PH - PH', value: 9
    value 'OTHER', '(7) Other', value: 7
    value 'PH_OPH', '(10) PH - OPH', value: 10
    value 'DAY_SHELTER', '(11) Day Shelter', value: 11
    value 'HP', '(12) HP', value: 12
    value 'PH_RRH', '(13) PH - RRH', value: 13
    value 'CE', '(14) CE', value: 14
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class RRHSubType < Types::BaseEnum
    description 'HUD RRHSubType (2.02.A)'
    graphql_name 'RRHSubType'
    value 'RRH_SERVICES_ONLY', '(1) RRH: Services Only', value: 1
    value 'RRH_HOUSING_WITH_OR_WITHOUT_SERVICES', '(2) RRH: Housing with or without services', value: 2
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class FundingSource < Types::BaseEnum
    description 'HUD FundingSource (2.06.1)'
    graphql_name 'FundingSource'
    value 'HUD_COC_HOMELESSNESS_PREVENTION', '(1) HUD: CoC - Homelessness Prevention (High Performing Communities Only)', value: 1
    value 'HUD_COC_PERMANENT_SUPPORTIVE_HOUSING', '(2) HUD: CoC - Permanent Supportive Housing', value: 2
    value 'HUD_COC_RAPID_RE_HOUSING', '(3) HUD: CoC - Rapid Re-Housing', value: 3
    value 'HUD_COC_SUPPORTIVE_SERVICES_ONLY', '(4) HUD: CoC - Supportive Services Only', value: 4
    value 'HUD_COC_TRANSITIONAL_HOUSING', '(5) HUD: CoC - Transitional Housing', value: 5
    value 'HUD_COC_SAFE_HAVEN', '(6) HUD: CoC - Safe Haven', value: 6
    value 'HUD_COC_SINGLE_ROOM_OCCUPANCY_SRO', '(7) HUD: CoC - Single Room Occupancy (SRO)', value: 7
    value 'HUD_ESG_EMERGENCY_SHELTER', '(8) HUD: ESG - Emergency Shelter (operating and/or essential services)', value: 8
    value 'HUD_ESG_HOMELESSNESS_PREVENTION', '(9) HUD: ESG - Homelessness Prevention', value: 9
    value 'HUD_ESG_RAPID_REHOUSING', '(10) HUD: ESG - Rapid Rehousing', value: 10
    value 'HUD_ESG_STREET_OUTREACH', '(11) HUD: ESG - Street Outreach', value: 11
    value 'HUD_RURAL_HOUSING_STABILITY_ASSISTANCE_PROGRAM_DEPRECATED', '(12) HUD: Rural Housing Stability Assistance Program [Deprecated]', value: 12
    value 'HUD_HOPWA_HOTEL_MOTEL_VOUCHERS', '(13) HUD: HOPWA - Hotel/Motel Vouchers', value: 13
    value 'HUD_HOPWA_HOUSING_INFORMATION', '(14) HUD: HOPWA - Housing Information', value: 14
    value 'HUD_HOPWA_PERMANENT_HOUSING', '(15) HUD: HOPWA - Permanent Housing (facility based or TBRA)', value: 15
    value 'HUD_HOPWA_PERMANENT_HOUSING_PLACEMENT', '(16) HUD: HOPWA - Permanent Housing Placement', value: 16
    value 'HUD_HOPWA_SHORT_TERM_RENT_MORTGAGE_UTILITY_ASSISTANCE', '(17) HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance', value: 17
    value 'HUD_HOPWA_SHORT_TERM_SUPPORTIVE_FACILITY', '(18) HUD: HOPWA - Short-Term Supportive Facility', value: 18
    value 'HUD_HOPWA_TRANSITIONAL_HOUSING', '(19) HUD: HOPWA - Transitional Housing (facility based or TBRA)', value: 19
    value 'HUD_HUD_VASH', '(20) HUD: HUD/VASH', value: 20
    value 'HHS_PATH_STREET_OUTREACH_SUPPORTIVE_SERVICES_ONLY', '(21) HHS: PATH - Street Outreach & Supportive Services Only', value: 21
    value 'HHS_RHY_BASIC_CENTER_PROGRAM', '(22) HHS: RHY - Basic Center Program (prevention and shelter)', value: 22
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
    value 'HUD_COC_JOINT_COMPONENT_RRH_PSH_DEPRECATED', '(49) HUD: CoC - Joint Component RRH/PSH [Deprecated]', value: 49
    value 'HUD_HOME', '(50) HUD: HOME', value: 50
    value 'HUD_HOME_ARP', '(51) HUD: HOME (ARP)', value: 51
    value 'HUD_PIH', '(52) HUD: PIH (Emergency Housing Voucher)', value: 52
    value 'HUD_ESG_RUSH', '(53) HUD: ESG - RUSH', value: 53
    value 'HUD_UNSHELTERED_SPECIAL_NOFO', '(54) HUD: Unsheltered Special NOFO', value: 54
    value 'HUD_RURAL_SPECIAL_NOFO', '(55) HUD: Rural Special NOFO', value: 55
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HouseholdType < Types::BaseEnum
    description 'HUD HouseholdType (2.07.4)'
    graphql_name 'HouseholdType'
    value 'HOUSEHOLDS_WITHOUT_CHILDREN', '(1) Households without children', value: 1
    value 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD', '(3) Households with at least one adult and one child', value: 3
    value 'HOUSEHOLDS_WITH_ONLY_CHILDREN', '(4) Households with only children', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class BedType < Types::BaseEnum
    description 'HUD BedType (2.07.5)'
    graphql_name 'BedType'
    value 'FACILITY_BASED', '(1) Facility-based', value: 1
    value 'VOUCHER', '(2) Voucher', value: 2
    value 'OTHER', '(3) Other', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class Availability < Types::BaseEnum
    description 'HUD Availability (2.07.6)'
    graphql_name 'Availability'
    value 'YEAR_ROUND', '(1) Year-round', value: 1
    value 'SEASONAL', '(2) Seasonal', value: 2
    value 'OVERFLOW', '(3) Overflow', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class CoCCodes < Types::BaseEnum
    description 'HUD CoCCodes (2.03.1)'
    graphql_name 'CoCCodes'
    value 'ANCHORAGE_COC', '(AK-500) Anchorage CoC', value: 'AK-500'
    value 'ALASKA_BALANCE_OF_STATE_COC', '(AK-501) Alaska Balance of State CoC', value: 'AK-501'
    value 'BIRMINGHAM_JEFFERSON_ST_CLAIR_SHELBY_COUNTIES_COC', '(AL-500) Birmingham/Jefferson, St. Clair, Shelby Counties CoC', value: 'AL-500'
    value 'MOBILE_CITY_COUNTY_BALDWIN_COUNTY_COC', '(AL-501) Mobile City & County/Baldwin County CoC', value: 'AL-501'
    value 'FLORENCE_NORTHWEST_ALABAMA_COC', '(AL-502) Florence/Northwest Alabama CoC', value: 'AL-502'
    value 'HUNTSVILLE_NORTH_ALABAMA_COC', '(AL-503) Huntsville/North Alabama CoC', value: 'AL-503'
    value 'MONTGOMERY_CITY_COUNTY_COC', '(AL-504) Montgomery City & County CoC', value: 'AL-504'
    value 'GADSDEN_NORTHEAST_ALABAMA_COC', '(AL-505) Gadsden/Northeast Alabama CoC', value: 'AL-505'
    value 'TUSCALOOSA_CITY_COUNTY_COC', '(AL-506) Tuscaloosa City & County CoC', value: 'AL-506'
    value 'ALABAMA_BALANCE_OF_STATE_COC', '(AL-507) Alabama Balance of State CoC', value: 'AL-507'
    value 'LITTLE_ROCK_CENTRAL_ARKANSAS_COC', '(AR-500) Little Rock/Central Arkansas CoC', value: 'AR-500'
    value 'FAYETTEVILLE_NORTHWEST_ARKANSAS_COC', '(AR-501) Fayetteville/Northwest Arkansas CoC', value: 'AR-501'
    value 'ARKANSAS_BALANCE_OF_STATE_COC', '(AR-503) Arkansas Balance of State CoC', value: 'AR-503'
    value 'SOUTHEAST_ARKANSAS_COC', '(AR-505) Southeast Arkansas CoC', value: 'AR-505'
    value 'FORT_SMITH_COC', '(AR-508) Fort Smith CoC', value: 'AR-508'
    value 'AMERICAN_SAMOA_COC', '(AS-500) American Samoa CoC', value: 'AS-500'
    value 'ARIZONA_BALANCE_OF_STATE_COC', '(AZ-500) Arizona Balance of State CoC', value: 'AZ-500'
    value 'TUCSON_PIMA_COUNTY_COC', '(AZ-501) Tucson/Pima County CoC', value: 'AZ-501'
    value 'PHOENIX_MESA_MARICOPA_COUNTY_COC', '(AZ-502) Phoenix, Mesa/Maricopa County CoC', value: 'AZ-502'
    value 'SAN_JOSE_SANTA_CLARA_CITY_COUNTY_COC', '(CA-500) San Jose/Santa Clara City & County CoC', value: 'CA-500'
    value 'SAN_FRANCISCO_COC', '(CA-501) San Francisco CoC', value: 'CA-501'
    value 'OAKLAND_BERKELEY_ALAMEDA_COUNTY_COC', '(CA-502) Oakland, Berkeley/Alameda County CoC', value: 'CA-502'
    value 'SACRAMENTO_CITY_COUNTY_COC', '(CA-503) Sacramento City & County CoC', value: 'CA-503'
    value 'SANTA_ROSA_PETALUMA_SONOMA_COUNTY_COC', '(CA-504) Santa Rosa, Petaluma/Sonoma County CoC', value: 'CA-504'
    value 'CONTRA_COSTA_COUNTY_COC', '(CA-505) Contra Costa County CoC', value: 'CA-505'
    value 'SALINAS_MONTEREY_SAN_BENITO_COUNTIES_COC', '(CA-506) Salinas/Monterey, San Benito Counties CoC', value: 'CA-506'
    value 'MARIN_COUNTY_COC', '(CA-507) Marin County CoC', value: 'CA-507'
    value 'WATSONVILLE_SANTA_CRUZ_CITY_COUNTY_COC', '(CA-508) Watsonville/Santa Cruz City & County CoC', value: 'CA-508'
    value 'MENDOCINO_COUNTY_COC', '(CA-509) Mendocino County CoC', value: 'CA-509'
    value 'TURLOCK_MODESTO_STANISLAUS_COUNTY_COC', '(CA-510) Turlock, Modesto/Stanislaus County CoC', value: 'CA-510'
    value 'STOCKTON_SAN_JOAQUIN_COUNTY_COC', '(CA-511) Stockton/San Joaquin County CoC', value: 'CA-511'
    value 'DALY_CITY_SAN_MATEO_COUNTY_COC', '(CA-512) Daly City/San Mateo County CoC', value: 'CA-512'
    value 'VISALIA_KINGS_TULARE_COUNTIES_COC', '(CA-513) Visalia/Kings, Tulare Counties CoC', value: 'CA-513'
    value 'FRESNO_CITY_COUNTY_MADERA_COUNTY_COC', '(CA-514) Fresno City & County/Madera County CoC', value: 'CA-514'
    value 'ROSEVILLE_ROCKLIN_PLACER_COUNTY', '(CA-515) Roseville, Rocklin/Placer County', value: 'CA-515'
    value 'REDDING_SHASTA_SISKIYOU_LASSEN_PLUMAS_DEL_NORTE_MODOC_SIERRA_COUNTIES_COC', '(CA-516) Redding/Shasta Siskiyou, Lassen, Plumas, Del Norte, Modoc, Sierra Counties CoC', value: 'CA-516'
    value 'NAPA_CITY_COUNTY_COC', '(CA-517) Napa City & County CoC', value: 'CA-517'
    value 'VALLEJO_SOLANO_COUNTY_COC', '(CA-518) Vallejo/Solano County CoC', value: 'CA-518'
    value 'CHICO_PARADISE_BUTTE_COUNTY_COC', '(CA-519) Chico, Paradise/Butte County CoC', value: 'CA-519'
    value 'MERCED_CITY_COUNTY_COC', '(CA-520) Merced City & County CoC', value: 'CA-520'
    value 'DAVIS_WOODLAND_YOLO_COUNTY_COC', '(CA-521) Davis, Woodland/Yolo County CoC', value: 'CA-521'
    value 'HUMBOLDT_COUNTY_COC', '(CA-522) Humboldt County CoC', value: 'CA-522'
    value 'COLUSA_GLEN_TRINITY_COUNTIES_COC', '(CA-523) Colusa, Glen, Trinity Counties CoC', value: 'CA-523'
    value 'YUBA_CITY_COUNTY_SUTTER_COUNTY_COC', '(CA-524) Yuba City & County/Sutter County CoC', value: 'CA-524'
    value 'EL_DORADO_COUNTY_COC', '(CA-525) El Dorado County CoC', value: 'CA-525'
    value 'AMADOR_CALAVERAS_MARIPOSA_TUOLUMNE_COUNTIES_COC', '(CA-526) Amador, Calaveras, Mariposa, Tuolumne Counties CoC', value: 'CA-526'
    value 'TEHAMA_COUNTY_COC', '(CA-527) Tehama County CoC', value: 'CA-527'
    value 'LAKE_COUNTY_COC', '(CA-529) Lake County CoC', value: 'CA-529'
    value 'ALPINE_INYO_MONO_COUNTIES_COC', '(CA-530) Alpine, Inyo, Mono Counties CoC', value: 'CA-530'
    value 'NEVADA_COUNTY_COC', '(CA-531) Nevada County CoC', value: 'CA-531'
    value 'LOS_ANGELES_CITY_COUNTY_COC', '(CA-600) Los Angeles City & County CoC', value: 'CA-600'
    value 'SAN_DIEGO_CITY_AND_COUNTY_COC', '(CA-601) San Diego City and County CoC', value: 'CA-601'
    value 'SANTA_ANA_ANAHEIM_ORANGE_COUNTY_COC', '(CA-602) Santa Ana, Anaheim/Orange County CoC', value: 'CA-602'
    value 'SANTA_MARIA_SANTA_BARBARA_COUNTY_COC', '(CA-603) Santa Maria/Santa Barbara County CoC', value: 'CA-603'
    value 'BAKERSFIELD_KERN_COUNTY_COC', '(CA-604) Bakersfield/Kern County CoC', value: 'CA-604'
    value 'LONG_BEACH_COC', '(CA-606) Long Beach CoC', value: 'CA-606'
    value 'PASADENA_COC', '(CA-607) Pasadena CoC', value: 'CA-607'
    value 'RIVERSIDE_CITY_COUNTY_COC', '(CA-608) Riverside City & County CoC', value: 'CA-608'
    value 'SAN_BERNARDINO_CITY_COUNTY_COC', '(CA-609) San Bernardino City & County CoC', value: 'CA-609'
    value 'OXNARD_SAN_BUENAVENTURA_VENTURA_COUNTY_COC', '(CA-611) Oxnard, San Buenaventura/Ventura County CoC', value: 'CA-611'
    value 'GLENDALE_COC', '(CA-612) Glendale CoC', value: 'CA-612'
    value 'IMPERIAL_COUNTY_COC', '(CA-613) Imperial County CoC', value: 'CA-613'
    value 'SAN_LUIS_OBISPO_COUNTY_COC', '(CA-614) San Luis Obispo County CoC', value: 'CA-614'
    value 'COLORADO_BALANCE_OF_STATE_COC', '(CO-500) Colorado Balance of State CoC', value: 'CO-500'
    value 'METROPOLITAN_DENVER_COC', '(CO-503) Metropolitan Denver CoC', value: 'CO-503'
    value 'COLORADO_SPRINGS_EL_PASO_COUNTY_COC', '(CO-504) Colorado Springs/El Paso County CoC', value: 'CO-504'
    value 'FORT_COLLINS_GREELEY_LOVELAND_LARIMER_WELD_COUNTIES_COC', '(CO-505) Fort Collins, Greeley, Loveland/Larimer, Weld Counties CoC', value: 'CO-505'
    value 'BRIDGEPORT_STAMFORD_NORWALK_DANBURY_FAIRFIELD_COUNTY_COC', '(CT-503) Bridgeport, Stamford, Norwalk, Danbury/Fairfield County CoC', value: 'CT-503'
    value 'CONNECTICUT_BALANCE_OF_STATE_COC', '(CT-505) Connecticut Balance of State CoC', value: 'CT-505'
    value 'DISTRICT_OF_COLUMBIA_COC', '(DC-500) District of Columbia CoC', value: 'DC-500'
    value 'DELAWARE_STATEWIDE_COC', '(DE-500) Delaware Statewide CoC', value: 'DE-500'
    value 'SARASOTA_BRADENTON_MANATEE_SARASOTA_COUNTIES_COC', '(FL-500) Sarasota, Bradenton/Manatee, Sarasota Counties CoC', value: 'FL-500'
    value 'TAMPA_HILLSBOROUGH_COUNTY_COC', '(FL-501) Tampa/Hillsborough County CoC', value: 'FL-501'
    value 'ST_PETERSBURG_CLEARWATER_LARGO_PINELLAS_COUNTY_COC', '(FL-502) St. Petersburg, Clearwater, Largo/Pinellas County CoC', value: 'FL-502'
    value 'LAKELAND_POLK_COUNTY_COC', '(FL-503) Lakeland/Polk County CoC', value: 'FL-503'
    value 'DELTONA_DAYTONA_BEACH_VOLUSIA_FLAGLER_COUNTIES_COC', '(FL-504) Deltona, Daytona Beach/Volusia, Flagler Counties CoC', value: 'FL-504'
    value 'FORT_WALTON_BEACH_OKALOOSA_WALTON_COUNTIES_COC', '(FL-505) Fort Walton Beach/Okaloosa, Walton Counties CoC', value: 'FL-505'
    value 'TALLAHASSEE_LEON_COUNTY_COC', '(FL-506) Tallahassee/Leon County CoC', value: 'FL-506'
    value 'ORLANDO_ORANGE_OSCEOLA_SEMINOLE_COUNTIES_COC', '(FL-507) Orlando/Orange, Osceola, Seminole Counties CoC', value: 'FL-507'
    value 'GAINESVILLE_ALACHUA_PUTNAM_COUNTIES_COC', '(FL-508) Gainesville/Alachua, Putnam Counties CoC', value: 'FL-508'
    value 'FORT_PIERCE_ST_LUCIE_INDIAN_RIVER_MARTIN_COUNTIES_COC', '(FL-509) Fort Pierce/St. Lucie, Indian River, Martin Counties CoC', value: 'FL-509'
    value 'JACKSONVILLE_DUVAL_CLAY_COUNTIES_COC', '(FL-510) Jacksonville-Duval, Clay Counties CoC', value: 'FL-510'
    value 'PENSACOLA_ESCAMBIA_SANTA_ROSA_COUNTIES_COC', '(FL-511) Pensacola/Escambia, Santa Rosa Counties CoC', value: 'FL-511'
    value 'ST_JOHNS_COUNTY_COC', '(FL-512) St. Johns County CoC', value: 'FL-512'
    value 'PALM_BAY_MELBOURNE_BREVARD_COUNTY_COC', '(FL-513) Palm Bay, Melbourne/Brevard County CoC', value: 'FL-513'
    value 'OCALA_MARION_COUNTY_COC', '(FL-514) Ocala/Marion County CoC', value: 'FL-514'
    value 'PANAMA_CITY_BAY_JACKSON_COUNTIES_COC', '(FL-515) Panama City/Bay, Jackson Counties CoC', value: 'FL-515'
    value 'HENDRY_HARDEE_HIGHLANDS_COUNTIES_COC', '(FL-517) Hendry, Hardee, Highlands Counties CoC', value: 'FL-517'
    value 'COLUMBIA_HAMILTON_LAFAYETTE_SUWANNEE_COUNTIES_COC', '(FL-518) Columbia, Hamilton, Lafayette, Suwannee Counties CoC', value: 'FL-518'
    value 'PASCO_COUNTY_COC', '(FL-519) Pasco County CoC', value: 'FL-519'
    value 'CITRUS_HERNANDO_LAKE_SUMTER_COUNTIES_COC', '(FL-520) Citrus, Hernando, Lake, Sumter Counties CoC', value: 'FL-520'
    value 'MIAMI_DADE_COUNTY_COC', '(FL-600) Miami-Dade County CoC', value: 'FL-600'
    value 'FT_LAUDERDALE_BROWARD_COUNTY_COC', '(FL-601) Ft Lauderdale/Broward County CoC', value: 'FL-601'
    value 'CHARLOTTE_COUNTY_COC', '(FL-602) Charlotte County CoC', value: 'FL-602'
    value 'FT_MYERS_CAPE_CORAL_LEE_COUNTY_COC', '(FL-603) Ft Myers, Cape Coral/Lee County CoC', value: 'FL-603'
    value 'MONROE_COUNTY_COC', '(FL-604) Monroe County CoC', value: 'FL-604'
    value 'WEST_PALM_BEACH_PALM_BEACH_COUNTY_COC', '(FL-605) West Palm Beach/Palm Beach County CoC', value: 'FL-605'
    value 'NAPLES_COLLIER_COUNTY_COC', '(FL-606) Naples/Collier County CoC', value: 'FL-606'
    value 'ATLANTA_COC', '(GA-500) Atlanta CoC', value: 'GA-500'
    value 'GEORGIA_BALANCE_OF_STATE_COC', '(GA-501) Georgia Balance of State CoC', value: 'GA-501'
    value 'FULTON_COUNTY_COC', '(GA-502) Fulton County CoC', value: 'GA-502'
    value 'ATHENS_CLARKE_COUNTY_COC', '(GA-503) Athens-Clarke County CoC', value: 'GA-503'
    value 'AUGUSTA_RICHMOND_COUNTY_COC', '(GA-504) Augusta-Richmond County CoC', value: 'GA-504'
    value 'COLUMBUS_MUSCOGEE_RUSSELL_COUNTY_COC', '(GA-505) Columbus-Muscogee/Russell County CoC', value: 'GA-505'
    value 'MARIETTA_COBB_COUNTY_COC', '(GA-506) Marietta/Cobb County CoC', value: 'GA-506'
    value 'SAVANNAH_CHATHAM_COUNTY_COC', '(GA-507) Savannah/Chatham County CoC', value: 'GA-507'
    value 'DE_KALB_COUNTY_COC', '(GA-508) DeKalb County CoC', value: 'GA-508'
    value 'GUAM_COC', '(GU-500) Guam CoC', value: 'GU-500'
    value 'HAWAII_BALANCE_OF_STATE_COC', '(HI-500) Hawaii Balance of State CoC', value: 'HI-500'
    value 'HONOLULU_CITY_AND_COUNTY_COC', '(HI-501) Honolulu City and County CoC', value: 'HI-501'
    value 'SIOUX_CITY_DAKOTA_WOODBURY_COUNTIES_COC', '(IA-500) Sioux City/Dakota, Woodbury Counties CoC', value: 'IA-500'
    value 'IOWA_BALANCE_OF_STATE_COC', '(IA-501) Iowa Balance of State CoC', value: 'IA-501'
    value 'DES_MOINES_POLK_COUNTY_COC', '(IA-502) Des Moines/Polk County CoC', value: 'IA-502'
    value 'BOISE_ADA_COUNTY_COC', '(ID-500) Boise/Ada County CoC', value: 'ID-500'
    value 'IDAHO_BALANCE_OF_STATE_COC', '(ID-501) Idaho Balance of State CoC', value: 'ID-501'
    value 'MC_HENRY_COUNTY_COC', '(IL-500) McHenry County CoC', value: 'IL-500'
    value 'ROCKFORD_DE_KALB_WINNEBAGO_BOONE_COUNTIES_COC', '(IL-501) Rockford/DeKalb, Winnebago, Boone Counties CoC', value: 'IL-501'
    value 'WAUKEGAN_NORTH_CHICAGO_LAKE_COUNTY_COC', '(IL-502) Waukegan, North Chicago/Lake County CoC', value: 'IL-502'
    value 'CHAMPAIGN_URBANA_RANTOUL_CHAMPAIGN_COUNTY_COC', '(IL-503) Champaign, Urbana, Rantoul/Champaign County CoC', value: 'IL-503'
    value 'MADISON_COUNTY_COC', '(IL-504) Madison County CoC', value: 'IL-504'
    value 'JOLIET_BOLINGBROOK_WILL_COUNTY_COC', '(IL-506) Joliet, Bolingbrook/Will County CoC', value: 'IL-506'
    value 'PEORIA_PEKIN_FULTON_TAZEWELL_PEORIA_WOODFORD_COUNTIES_COC', '(IL-507) Peoria, Pekin/Fulton, Tazewell, Peoria, Woodford Counties CoC', value: 'IL-507'
    value 'EAST_ST_LOUIS_BELLEVILLE_ST_CLAIR_COUNTY_COC', '(IL-508) East St. Louis, Belleville/St. Clair County CoC', value: 'IL-508'
    value 'CHICAGO_COC', '(IL-510) Chicago CoC', value: 'IL-510'
    value 'COOK_COUNTY_COC', '(IL-511) Cook County CoC', value: 'IL-511'
    value 'BLOOMINGTON_CENTRAL_ILLINOIS_COC', '(IL-512) Bloomington/Central Illinois CoC', value: 'IL-512'
    value 'SPRINGFIELD_SANGAMON_COUNTY_COC', '(IL-513) Springfield/Sangamon County CoC', value: 'IL-513'
    value 'DU_PAGE_COUNTY_COC', '(IL-514) DuPage County CoC', value: 'IL-514'
    value 'SOUTH_CENTRAL_ILLINOIS_COC', '(IL-515) South Central Illinois CoC', value: 'IL-515'
    value 'DECATUR_MACON_COUNTY_COC', '(IL-516) Decatur/Macon County CoC', value: 'IL-516'
    value 'AURORA_ELGIN_KANE_COUNTY_COC', '(IL-517) Aurora, Elgin/Kane County CoC', value: 'IL-517'
    value 'ROCK_ISLAND_MOLINE_NORTHWESTERN_ILLINOIS_COC', '(IL-518) Rock Island, Moline/Northwestern Illinois CoC', value: 'IL-518'
    value 'WEST_CENTRAL_ILLINOIS_COC', '(IL-519) West Central Illinois CoC', value: 'IL-519'
    value 'SOUTHERN_ILLINOIS_COC', '(IL-520) Southern Illinois CoC', value: 'IL-520'
    value 'INDIANA_BALANCE_OF_STATE_COC', '(IN-502) Indiana Balance of State CoC', value: 'IN-502'
    value 'INDIANAPOLIS_COC', '(IN-503) Indianapolis CoC', value: 'IN-503'
    value 'WICHITA_SEDGWICK_COUNTY_COC', '(KS-502) Wichita/Sedgwick County CoC', value: 'KS-502'
    value 'TOPEKA_SHAWNEE_COUNTY_COC', '(KS-503) Topeka/Shawnee County CoC', value: 'KS-503'
    value 'OVERLAND_PARK_SHAWNEE_JOHNSON_COUNTY_COC', '(KS-505) Overland Park, Shawnee/Johnson County CoC', value: 'KS-505'
    value 'KANSAS_BALANCE_OF_STATE_COC', '(KS-507) Kansas Balance of State CoC', value: 'KS-507'
    value 'KENTUCKY_BALANCE_OF_STATE_COC', '(KY-500) Kentucky Balance of State CoC', value: 'KY-500'
    value 'LOUISVILLE_JEFFERSON_COUNTY_COC', '(KY-501) Louisville-Jefferson County CoC', value: 'KY-501'
    value 'LEXINGTON_FAYETTE_COUNTY_COC', '(KY-502) Lexington-Fayette County CoC', value: 'KY-502'
    value 'LAFAYETTE_ACADIANA_REGIONAL_COC', '(LA-500) Lafayette/Acadiana Regional CoC', value: 'LA-500'
    value 'SHREVEPORT_BOSSIER_NORTHWEST_LOUISIANA_COC', '(LA-502) Shreveport, Bossier/Northwest Louisiana CoC', value: 'LA-502'
    value 'NEW_ORLEANS_JEFFERSON_PARISH_COC', '(LA-503) New Orleans/Jefferson Parish CoC', value: 'LA-503'
    value 'MONROE_NORTHEAST_LOUISIANA_COC', '(LA-505) Monroe/Northeast Louisiana CoC', value: 'LA-505'
    value 'SLIDELL_SOUTHEAST_LOUISIANA_COC', '(LA-506) Slidell/Southeast Louisiana CoC', value: 'LA-506'
    value 'ALEXANDRIA_CENTRAL_LOUISIANA_COC', '(LA-507) Alexandria/Central Louisiana CoC', value: 'LA-507'
    value 'LOUISIANA_BALANCE_OF_STATE_COC', '(LA-509) Louisiana Balance of State CoC', value: 'LA-509'
    value 'BOSTON_COC', '(MA-500) Boston CoC', value: 'MA-500'
    value 'LYNN_COC', '(MA-502) Lynn CoC', value: 'MA-502'
    value 'CAPE_COD_ISLANDS_COC', '(MA-503) Cape Cod Islands CoC', value: 'MA-503'
    value 'SPRINGFIELD_HAMPDEN_COUNTY_COC', '(MA-504) Springfield/Hampden County CoC', value: 'MA-504'
    value 'NEW_BEDFORD_COC', '(MA-505) New Bedford CoC', value: 'MA-505'
    value 'WORCESTER_CITY_COUNTY_COC', '(MA-506) Worcester City & County CoC', value: 'MA-506'
    value 'PITTSFIELD_BERKSHIRE_FRANKLIN_HAMPSHIRE_COUNTIES_COC', '(MA-507) Pittsfield/Berkshire, Franklin, Hampshire Counties CoC', value: 'MA-507'
    value 'CAMBRIDGE_COC', '(MA-509) Cambridge CoC', value: 'MA-509'
    value 'QUINCY_BROCKTON_WEYMOUTH_PLYMOUTH_CITY_AND_COUNTY_COC', '(MA-511) Quincy, Brockton, Weymouth, Plymouth City and County CoC', value: 'MA-511'
    value 'FALL_RIVER_COC', '(MA-515) Fall River CoC', value: 'MA-515'
    value 'MASSACHUSETTS_BALANCE_OF_STATE_COC', '(MA-516) Massachusetts Balance of State CoC', value: 'MA-516'
    value 'ATTLEBORO_TAUNTON_BRISTOL_COUNTY_COC', '(MA-519) Attleboro, Taunton/Bristol County CoC', value: 'MA-519'
    value 'BALTIMORE_COC', '(MD-501) Baltimore CoC', value: 'MD-501'
    value 'ANNAPOLIS_ANNE_ARUNDEL_COUNTY_COC', '(MD-503) Annapolis/Anne Arundel County CoC', value: 'MD-503'
    value 'HOWARD_COUNTY_COC', '(MD-504) Howard County CoC', value: 'MD-504'
    value 'BALTIMORE_COUNTY_COC', '(MD-505) Baltimore County CoC', value: 'MD-505'
    value 'CARROLL_COUNTY_COC', '(MD-506) Carroll County CoC', value: 'MD-506'
    value 'FREDERICK_CITY_COUNTY_COC', '(MD-509) Frederick City & County CoC', value: 'MD-509'
    value 'MID_SHORE_REGIONAL_COC', '(MD-511) Mid-Shore Regional CoC', value: 'MD-511'
    value 'WICOMICO_SOMERSET_WORCESTER_COUNTIES_COC', '(MD-513) Wicomico, Somerset, Worcester Counties CoC', value: 'MD-513'
    value 'MARYLAND_BALANCE_OF_SATE', '(MD-514) Maryland Balance of Sate', value: 'MD-514'
    value 'PRINCE_GEORGE_S_COUNTY_COC', "(MD-600) Prince George's County CoC", value: 'MD-600'
    value 'MONTGOMERY_COUNTY_COC', '(MD-601) Montgomery County CoC', value: 'MD-601'
    value 'MAINE_STATEWIDE_COC', '(ME-500) Maine Statewide CoC', value: 'ME-500'
    value 'MICHIGAN_BALANCE_OF_STATE_COC', '(MI-500) Michigan Balance of State CoC', value: 'MI-500'
    value 'DETROIT_COC', '(MI-501) Detroit CoC', value: 'MI-501'
    value 'DEARBORN_DEARBORN_HEIGHTS_WESTLAND_WAYNE_COUNTY_COC', '(MI-502) Dearborn, Dearborn Heights, Westland/Wayne County CoC', value: 'MI-502'
    value 'ST_CLAIR_SHORES_WARREN_MACOMB_COUNTY_COC', '(MI-503) St. Clair Shores, Warren/Macomb County CoC', value: 'MI-503'
    value 'PONTIAC_ROYAL_OAK_OAKLAND_COUNTY_COC', '(MI-504) Pontiac, Royal Oak/Oakland County CoC', value: 'MI-504'
    value 'FLINT_GENESEE_COUNTY_COC', '(MI-505) Flint/Genesee County CoC', value: 'MI-505'
    value 'GRAND_RAPIDS_WYOMING_KENT_COUNTY_COC', '(MI-506) Grand Rapids, Wyoming/Kent County CoC', value: 'MI-506'
    value 'PORTAGE_KALAMAZOO_CITY_COUNTY_COC', '(MI-507) Portage, Kalamazoo City & County CoC', value: 'MI-507'
    value 'LANSING_EAST_LANSING_INGHAM_COUNTY_COC', '(MI-508) Lansing, East Lansing/Ingham County CoC', value: 'MI-508'
    value 'WASHTENAW_COUNTY_COC', '(MI-509) Washtenaw County CoC', value: 'MI-509'
    value 'SAGINAW_CITY_COUNTY_COC', '(MI-510) Saginaw City & County CoC', value: 'MI-510'
    value 'LENAWEE_COUNTY_COC', '(MI-511) Lenawee County CoC', value: 'MI-511'
    value 'GRAND_TRAVERSE_ANTRIM_LEELANAU_COUNTIES_COC', '(MI-512) Grand Traverse, Antrim, Leelanau Counties CoC', value: 'MI-512'
    value 'BATTLE_CREEK_CALHOUN_COUNTY_COC', '(MI-514) Battle Creek/Calhoun County CoC', value: 'MI-514'
    value 'MONROE_CITY_COUNTY_COC', '(MI-515) Monroe City & County CoC', value: 'MI-515'
    value 'NORTON_SHORES_MUSKEGON_CITY_COUNTY_COC', '(MI-516) Norton Shores, Muskegon City & County CoC', value: 'MI-516'
    value 'JACKSON_CITY_COUNTY_COC', '(MI-517) Jackson City & County CoC', value: 'MI-517'
    value 'LIVINGSTON_COUNTY_COC', '(MI-518) Livingston County CoC', value: 'MI-518'
    value 'HOLLAND_OTTAWA_COUNTY_COC', '(MI-519) Holland/Ottawa County CoC', value: 'MI-519'
    value 'EATON_COUNTY_COC', '(MI-523) Eaton County CoC', value: 'MI-523'
    value 'MINNEAPOLIS_HENNEPIN_COUNTY_COC', '(MN-500) Minneapolis/Hennepin County CoC', value: 'MN-500'
    value 'ST_PAUL_RAMSEY_COUNTY_COC', '(MN-501) St. Paul/Ramsey County CoC', value: 'MN-501'
    value 'ROCHESTER_SOUTHEAST_MINNESOTA_COC', '(MN-502) Rochester/Southeast Minnesota CoC', value: 'MN-502'
    value 'DAKOTA_ANOKA_WASHINGTON_SCOTT_CARVER_COUNTIES_COC', '(MN-503) Dakota, Anoka, Washington, Scott, Carver Counties CoC', value: 'MN-503'
    value 'NORTHEAST_MINNESOTA_COC', '(MN-504) Northeast Minnesota CoC', value: 'MN-504'
    value 'ST_CLOUD_CENTRAL_MINNESOTA_COC', '(MN-505) St. Cloud/Central Minnesota CoC', value: 'MN-505'
    value 'NORTHWEST_MINNESOTA_COC', '(MN-506) Northwest Minnesota CoC', value: 'MN-506'
    value 'MOORHEAD_WEST_CENTRAL_MINNESOTA_COC', '(MN-508) Moorhead/West Central Minnesota CoC', value: 'MN-508'
    value 'DULUTH_ST_LOUIS_COUNTY_COC', '(MN-509) Duluth/St. Louis County CoC', value: 'MN-509'
    value 'SOUTHWEST_MINNESOTA_COC', '(MN-511) Southwest Minnesota CoC', value: 'MN-511'
    value 'ST_LOUIS_COUNTY_COC', '(MO-500) St. Louis County CoC', value: 'MO-500'
    value 'ST_LOUIS_COC', '(MO-501) St. Louis CoC', value: 'MO-501'
    value 'ST_CHARLES_LINCOLN_WARREN_COUNTIES_COC', '(MO-503) St. Charles, Lincoln, Warren Counties CoC', value: 'MO-503'
    value 'SPRINGFIELD_GREENE_CHRISTIAN_WEBSTER_COUNTIES_COC', '(MO-600) Springfield/Greene, Christian, Webster Counties CoC', value: 'MO-600'
    value 'JOPLIN_JASPER_NEWTON_COUNTIES_COC', '(MO-602) Joplin/Jasper, Newton Counties CoC', value: 'MO-602'
    value 'ST_JOSEPH_ANDREW_BUCHANAN_DE_KALB_COUNTIES_COC', '(MO-603) St. Joseph/Andrew, Buchanan, DeKalb Counties CoC', value: 'MO-603'
    value 'KANSAS_CITY_MO_KS_INDEPENDENCE_LEE_S_SUMMIT_JACKSON_WYANDOTTE_COUNTIES_COC', '(MO-604) Kansas City (MO&KS), Independence, Lee’s Summit/Jackson, Wyandotte Counties CoC', value: 'MO-604'
    value 'MISSOURI_BALANCE_OF_STATE_COC', '(MO-606) Missouri Balance of State CoC', value: 'MO-606'
    value 'NORTHERN_MARIANA_ISLANDS_COC', '(MP-500) Northern Mariana Islands CoC', value: 'MP-500'
    value 'JACKSON_RANKIN_MADISON_COUNTIES_COC', '(MS-500) Jackson/Rankin, Madison Counties CoC', value: 'MS-500'
    value 'MISSISSIPPI_BALANCE_OF_STATE_COC', '(MS-501) Mississippi Balance of State CoC', value: 'MS-501'
    value 'GULF_PORT_GULF_COAST_REGIONAL_COC', '(MS-503) Gulf Port/Gulf Coast Regional CoC', value: 'MS-503'
    value 'MONTANA_STATEWIDE_COC', '(MT-500) Montana Statewide CoC', value: 'MT-500'
    value 'WINSTON_SALEM_FORSYTH_COUNTY_COC', '(NC-500) Winston-Salem/Forsyth County CoC', value: 'NC-500'
    value 'ASHEVILLE_BUNCOMBE_COUNTY_COC', '(NC-501) Asheville/Buncombe County CoC', value: 'NC-501'
    value 'DURHAM_CITY_COUNTY_COC', '(NC-502) Durham City & County CoC', value: 'NC-502'
    value 'NORTH_CAROLINA_BALANCE_OF_STATE_COC', '(NC-503) North Carolina Balance of State CoC', value: 'NC-503'
    value 'GREENSBORO_HIGH_POINT_GUILFORD_COUNTY_COC', '(NC-504) Greensboro, High Point/Guilford County CoC', value: 'NC-504'
    value 'CHARLOTTE_MECKLENBURG_COUNTY_COC', '(NC-505) Charlotte/Mecklenburg County CoC', value: 'NC-505'
    value 'WILMINGTON_BRUNSWICK_NEW_HANOVER_PENDER_COUNTIES_COC', '(NC-506) Wilmington/Brunswick, New Hanover, Pender Counties CoC', value: 'NC-506'
    value 'RALEIGH_WAKE_COUNTY_COC', '(NC-507) Raleigh/Wake County CoC', value: 'NC-507'
    value 'GASTONIA_CLEVELAND_GASTON_LINCOLN_COUNTIES_COC', '(NC-509) Gastonia/Cleveland, Gaston, Lincoln Counties CoC', value: 'NC-509'
    value 'FAYETTEVILLE_CUMBERLAND_COUNTY_COC', '(NC-511) Fayetteville/Cumberland County CoC', value: 'NC-511'
    value 'CHAPEL_HILL_ORANGE_COUNTY_COC', '(NC-513) Chapel Hill/Orange County CoC', value: 'NC-513'
    value 'NORTHWEST_NORTH_CAROLINA_COC', '(NC-516) Northwest North Carolina CoC', value: 'NC-516'
    value 'NORTH_DAKOTA_STATEWIDE_COC', '(ND-500) North Dakota Statewide CoC', value: 'ND-500'
    value 'NEBRASKA_BALANCE_OF_STATE_COC', '(NE-500) Nebraska Balance of State CoC', value: 'NE-500'
    value 'OMAHA_COUNCIL_BLUFFS_COC', '(NE-501) Omaha, Council Bluffs CoC', value: 'NE-501'
    value 'LINCOLN_COC', '(NE-502) Lincoln CoC', value: 'NE-502'
    value 'NEW_HAMPSHIRE_BALANCE_OF_STATE_COC', '(NH-500) New Hampshire Balance of State CoC', value: 'NH-500'
    value 'MANCHESTER_COC', '(NH-501) Manchester CoC', value: 'NH-501'
    value 'NASHUA_HILLSBOROUGH_COUNTY_COC', '(NH-502) Nashua/Hillsborough County CoC', value: 'NH-502'
    value 'ATLANTIC_CITY_COUNTY_COC', '(NJ-500) Atlantic City & County CoC', value: 'NJ-500'
    value 'BERGEN_COUNTY_COC', '(NJ-501) Bergen County CoC', value: 'NJ-501'
    value 'BURLINGTON_COUNTY_COC', '(NJ-502) Burlington County CoC', value: 'NJ-502'
    value 'CAMDEN_CITY_COUNTY_GLOUCESTER_CAPE_MAY_CUMBERLAND_COUNTIES_COC', '(NJ-503) Camden City & County/Gloucester, Cape May, Cumberland Counties CoC', value: 'NJ-503'
    value 'NEWARK_ESSEX_COUNTY_COC', '(NJ-504) Newark/Essex County CoC', value: 'NJ-504'
    value 'JERSEY_CITY_BAYONNE_HUDSON_COUNTY_COC', '(NJ-506) Jersey City, Bayonne/Hudson County CoC', value: 'NJ-506'
    value 'NEW_BRUNSWICK_MIDDLESEX_COUNTY_COC', '(NJ-507) New Brunswick/Middlesex County CoC', value: 'NJ-507'
    value 'MONMOUTH_COUNTY_COC', '(NJ-508) Monmouth County CoC', value: 'NJ-508'
    value 'MORRIS_COUNTY_COC', '(NJ-509) Morris County CoC', value: 'NJ-509'
    value 'LAKEWOOD_TOWNSHIP_OCEAN_COUNTY_COC', '(NJ-510) Lakewood Township/Ocean County CoC', value: 'NJ-510'
    value 'PATERSON_PASSAIC_COUNTY_COC', '(NJ-511) Paterson/Passaic County CoC', value: 'NJ-511'
    value 'SALEM_COUNTY_COC', '(NJ-512) Salem County CoC', value: 'NJ-512'
    value 'SOMERSET_COUNTY_COC', '(NJ-513) Somerset County CoC', value: 'NJ-513'
    value 'TRENTON_MERCER_COUNTY_COC', '(NJ-514) Trenton/Mercer County CoC', value: 'NJ-514'
    value 'ELIZABETH_UNION_COUNTY_COC', '(NJ-515) Elizabeth/Union County CoC', value: 'NJ-515'
    value 'WARREN_SUSSEX_HUNTERDON_COUNTIES_COC', '(NJ-516) Warren, Sussex, Hunterdon Counties CoC', value: 'NJ-516'
    value 'ALBUQUERQUE_COC', '(NM-500) Albuquerque CoC', value: 'NM-500'
    value 'NEW_MEXICO_BALANCE_OF_STATE_COC', '(NM-501) New Mexico Balance of State CoC', value: 'NM-501'
    value 'LAS_VEGAS_CLARK_COUNTY_COC', '(NV-500) Las Vegas/Clark County CoC', value: 'NV-500'
    value 'RENO_SPARKS_WASHOE_COUNTY_COC', '(NV-501) Reno, Sparks/Washoe County CoC', value: 'NV-501'
    value 'NEVADA_BALANCE_OF_STATE_COC', '(NV-502) Nevada Balance of State CoC', value: 'NV-502'
    value 'ROCHESTER_IRONDEQUOIT_GREECE_MONROE_COUNTY_COC', '(NY-500) Rochester, Irondequoit, Greece/Monroe County CoC', value: 'NY-500'
    value 'ELMIRA_STEUBEN_ALLEGANY_LIVINGSTON_CHEMUNG_SCHUYLER_COUNTIES_COC', '(NY-501) Elmira/Steuben, Allegany, Livingston, Chemung, Schuyler Counties CoC', value: 'NY-501'
    value 'ALBANY_CITY_COUNTY_COC', '(NY-503) Albany City & County CoC', value: 'NY-503'
    value 'SYRACUSE_AUBURN_ONONDAGA_OSWEGO_CAYUGA_COUNTIES_COC', '(NY-505) Syracuse, Auburn/Onondaga, Oswego, Cayuga Counties CoC', value: 'NY-505'
    value 'SCHENECTADY_CITY_COUNTY_COC', '(NY-507) Schenectady City & County CoC', value: 'NY-507'
    value 'BUFFALO_NIAGARA_FALLS_ERIE_NIAGARA_ORLEANS_GENESEE_WYOMING_COUNTIES_COC', '(NY-508) Buffalo, Niagara Falls/Erie, Niagara, Orleans, Genesee, Wyoming Counties CoC', value: 'NY-508'
    value 'ITHACA_TOMPKINS_COUNTY_COC', '(NY-510) Ithaca/Tompkins County CoC', value: 'NY-510'
    value 'BINGHAMTON_UNION_TOWN_BROOME_OTSEGO_CHENANGO_DELAWARE_CORTLAND_TIOGA_COUNTIES_COC', '(NY-511) Binghamton, Union Town/Broome, Otsego, Chenango, Delaware, Cortland, Tioga Counties CoC', value: 'NY-511'
    value 'TROY_RENSSELAER_COUNTY_COC', '(NY-512) Troy/Rensselaer County CoC', value: 'NY-512'
    value 'WAYNE_ONTARIO_SENECA_YATES_COUNTIES_COC', '(NY-513) Wayne, Ontario, Seneca, Yates Counties CoC', value: 'NY-513'
    value 'JAMESTOWN_DUNKIRK_CHAUTAUQUA_COUNTY_COC', '(NY-514) Jamestown, Dunkirk/Chautauqua County CoC', value: 'NY-514'
    value 'UTICA_ROME_ONEIDA_MADISON_COUNTIES_COC', '(NY-518) Utica, Rome/Oneida, Madison Counties CoC', value: 'NY-518'
    value 'COLUMBIA_GREENE_COUNTIES_COC', '(NY-519) Columbia, Greene Counties CoC', value: 'NY-519'
    value 'FRANKLIN_ESSEX_COUNTIES_COC', '(NY-520) Franklin, Essex Counties CoC', value: 'NY-520'
    value 'JEFFERSON_LEWIS_ST_LAWRENCE_COUNTIES_COC', '(NY-522) Jefferson, Lewis, St. Lawrence Counties CoC', value: 'NY-522'
    value 'GLENS_FALLS_SARATOGA_SPRINGS_SARATOGA_WASHINGTON_WARREN_HAMILTON_COUNTIES_COC', '(NY-523) Glens Falls, Saratoga Springs/Saratoga, Washington, Warren, Hamilton Counties CoC', value: 'NY-523'
    value 'NEW_YORK_BALANCE_OF_STATE_COC', '(NY-525) New York Balance of State CoC', value: 'NY-525'
    value 'NEW_YORK_CITY_COC', '(NY-600) New York City CoC', value: 'NY-600'
    value 'POUGHKEEPSIE_DUTCHESS_COUNTY_COC', '(NY-601) Poughkeepsie/Dutchess County CoC', value: 'NY-601'
    value 'NEWBURGH_MIDDLETOWN_ORANGE_COUNTY_COC', '(NY-602) Newburgh, Middletown/Orange County CoC', value: 'NY-602'
    value 'NASSAU_SUFFOLK_COUNTIES_COC', '(NY-603) Nassau, Suffolk Counties CoC', value: 'NY-603'
    value 'YONKERS_MOUNT_VERNON_WESTCHESTER_COUNTY_COC', '(NY-604) Yonkers, Mount Vernon/Westchester County CoC', value: 'NY-604'
    value 'ROCKLAND_COUNTY_COC', '(NY-606) Rockland County CoC', value: 'NY-606'
    value 'KINGSTON_ULSTER_COUNTY_COC', '(NY-608) Kingston/Ulster County CoC', value: 'NY-608'
    value 'CINCINNATI_HAMILTON_COUNTY_COC', '(OH-500) Cincinnati/Hamilton County CoC', value: 'OH-500'
    value 'TOLEDO_LUCAS_COUNTY_COC', '(OH-501) Toledo/Lucas County CoC', value: 'OH-501'
    value 'CLEVELAND_CUYAHOGA_COUNTY_COC', '(OH-502) Cleveland/Cuyahoga County CoC', value: 'OH-502'
    value 'COLUMBUS_FRANKLIN_COUNTY_COC', '(OH-503) Columbus/Franklin County CoC', value: 'OH-503'
    value 'YOUNGSTOWN_MAHONING_COUNTY_COC', '(OH-504) Youngstown/Mahoning County CoC', value: 'OH-504'
    value 'DAYTON_KETTERING_MONTGOMERY_COUNTY_COC', '(OH-505) Dayton, Kettering/Montgomery County CoC', value: 'OH-505'
    value 'AKRON_BARBERTON_SUMMIT_COUNTY_COC', '(OH-506) Akron, Barberton/Summit County CoC', value: 'OH-506'
    value 'OHIO_BALANCE_OF_STATE_COC', '(OH-507) Ohio Balance of State CoC', value: 'OH-507'
    value 'CANTON_MASSILLON_ALLIANCE_STARK_COUNTY_COC', '(OH-508) Canton, Massillon, Alliance/Stark County CoC', value: 'OH-508'
    value 'NORTH_CENTRAL_OKLAHOMA_COC', '(OK-500) North Central Oklahoma CoC', value: 'OK-500'
    value 'TULSA_CITY_COUNTY_COC', '(OK-501) Tulsa City & County CoC', value: 'OK-501'
    value 'OKLAHOMA_CITY_COC', '(OK-502) Oklahoma City CoC', value: 'OK-502'
    value 'OKLAHOMA_BALANCE_OF_STATE_COC', '(OK-503) Oklahoma Balance of State CoC', value: 'OK-503'
    value 'NORMAN_CLEVELAND_COUNTY_COC', '(OK-504) Norman/Cleveland County CoC', value: 'OK-504'
    value 'NORTHEAST_OKLAHOMA_COC', '(OK-505) Northeast Oklahoma CoC', value: 'OK-505'
    value 'SOUTHWEST_OKLAHOMA_REGIONAL_COC', '(OK-506) Southwest Oklahoma Regional CoC', value: 'OK-506'
    value 'SOUTHEASTERN_OKLAHOMA_REGIONAL_COC', '(OK-507) Southeastern Oklahoma Regional CoC', value: 'OK-507'
    value 'EUGENE_SPRINGFIELD_LANE_COUNTY_COC', '(OR-500) Eugene, Springfield/Lane County CoC', value: 'OR-500'
    value 'PORTLAND_GRESHAM_MULTNOMAH_COUNTY_COC', '(OR-501) Portland, Gresham/Multnomah County CoC', value: 'OR-501'
    value 'MEDFORD_ASHLAND_JACKSON_COUNTY_COC', '(OR-502) Medford, Ashland/Jackson County CoC', value: 'OR-502'
    value 'CENTRAL_OREGON_COC', '(OR-503) Central Oregon CoC', value: 'OR-503'
    value 'SALEM_MARION_POLK_COUNTIES_COC', '(OR-504) Salem/Marion, Polk Counties CoC', value: 'OR-504'
    value 'OREGON_BALANCE_OF_STATE_COC', '(OR-505) Oregon Balance of State CoC', value: 'OR-505'
    value 'HILLSBORO_BEAVERTON_WASHINGTON_COUNTY_COC', '(OR-506) Hillsboro, Beaverton/Washington County CoC', value: 'OR-506'
    value 'CLACKAMAS_COUNTY_COC', '(OR-507) Clackamas County CoC', value: 'OR-507'
    value 'PHILADELPHIA_COC', '(PA-500) Philadelphia CoC', value: 'PA-500'
    value 'HARRISBURG_DAUPHIN_COUNTY_COC', '(PA-501) Harrisburg/Dauphin County CoC', value: 'PA-501'
    value 'UPPER_DARBY_CHESTER_HAVERFORD_DELAWARE_COUNTY_COC', '(PA-502) Upper Darby, Chester, Haverford/Delaware County CoC', value: 'PA-502'
    value 'WILKES_BARRE_HAZLETON_LUZERNE_COUNTY_COC', '(PA-503) Wilkes-Barre, Hazleton/ Luzerne County CoC', value: 'PA-503'
    value 'LOWER_MERION_NORRISTOWN_ABINGTON_MONTGOMERY_COUNTY_COC', '(PA-504) Lower Merion, Norristown, Abington/Montgomery County CoC', value: 'PA-504'
    value 'CHESTER_COUNTY_COC', '(PA-505) Chester County CoC', value: 'PA-505'
    value 'READING_BERKS_COUNTY_COC', '(PA-506) Reading/Berks County CoC', value: 'PA-506'
    value 'SCRANTON_LACKAWANNA_COUNTY_COC', '(PA-508) Scranton/Lackawanna County CoC', value: 'PA-508'
    value 'EASTERN_PENNSYLVANIA_COC', '(PA-509) Eastern Pennsylvania CoC', value: 'PA-509'
    value 'LANCASTER_CITY_COUNTY_COC', '(PA-510) Lancaster City & County CoC', value: 'PA-510'
    value 'BRISTOL_BENSALEM_BUCKS_COUNTY_COC', '(PA-511) Bristol, Bensalem/Bucks County CoC', value: 'PA-511'
    value 'YORK_CITY_COUNTY_COC', '(PA-512) York City & County CoC', value: 'PA-512'
    value 'PITTSBURGH_MC_KEESPORT_PENN_HILLS_ALLEGHENY_COUNTY_COC', '(PA-600) Pittsburgh, McKeesport, Penn Hills/Allegheny County CoC', value: 'PA-600'
    value 'WESTERN_PENNSYLVANIA_COC', '(PA-601) Western Pennsylvania CoC', value: 'PA-601'
    value 'BEAVER_COUNTY_COC', '(PA-603) Beaver County CoC', value: 'PA-603'
    value 'ERIE_CITY_COUNTY_COC', '(PA-605) Erie City & County CoC', value: 'PA-605'
    value 'PUERTO_RICO_BALANCE_OF_COMMONWEALTH_COC', '(PR-502) Puerto Rico Balance of Commonwealth CoC', value: 'PR-502'
    value 'SOUTH_SOUTHEAST_PUERTO_RICO_COC', '(PR-503) South-Southeast Puerto Rico CoC', value: 'PR-503'
    value 'RHODE_ISLAND_STATEWIDE_COC', '(RI-500) Rhode Island Statewide CoC', value: 'RI-500'
    value 'CHARLESTON_LOW_COUNTRY_COC', '(SC-500) Charleston/Low Country CoC', value: 'SC-500'
    value 'GREENVILLE_ANDERSON_SPARTANBURG_UPSTATE_COC', '(SC-501) Greenville, Anderson, Spartanburg/Upstate CoC', value: 'SC-501'
    value 'COLUMBIA_MIDLANDS_COC', '(SC-502) Columbia/Midlands CoC', value: 'SC-502'
    value 'SUMTER_CITY_COUNTY_COC', '(SC-503) Sumter City & County CoC', value: 'SC-503'
    value 'SOUTH_DAKOTA_STATEWIDE_COC', '(SD-500) South Dakota Statewide CoC', value: 'SD-500'
    value 'CHATTANOOGA_SOUTHEAST_TENNESSEE_COC', '(TN-500) Chattanooga/Southeast Tennessee CoC', value: 'TN-500'
    value 'MEMPHIS_SHELBY_COUNTY_COC', '(TN-501) Memphis/Shelby County CoC', value: 'TN-501'
    value 'KNOXVILLE_KNOX_COUNTY_COC', '(TN-502) Knoxville/Knox County CoC', value: 'TN-502'
    value 'CENTRAL_TENNESSEE_COC', '(TN-503) Central Tennessee CoC', value: 'TN-503'
    value 'NASHVILLE_DAVIDSON_COUNTY_COC', '(TN-504) Nashville-Davidson County CoC', value: 'TN-504'
    value 'UPPER_CUMBERLAND_COC', '(TN-506) Upper Cumberland CoC', value: 'TN-506'
    value 'JACKSON_WEST_TENNESSEE_COC', '(TN-507) Jackson/West Tennessee CoC', value: 'TN-507'
    value 'APPALACHIAN_REGIONAL_COC', '(TN-509) Appalachian Regional CoC', value: 'TN-509'
    value 'MURFREESBORO_RUTHERFORD_COUNTY_COC', '(TN-510) Murfreesboro/Rutherford County CoC', value: 'TN-510'
    value 'MORRISTOWN_BLOUNT_SEVIER_CAMPBELL_COCKE_COUNTIES_COC', '(TN-512) Morristown/Blount, Sevier, Campbell, Cocke Counties CoC', value: 'TN-512'
    value 'SAN_ANTONIO_BEXAR_COUNTY_COC', '(TX-500) San Antonio/Bexar County CoC', value: 'TX-500'
    value 'AUSTIN_TRAVIS_COUNTY_COC', '(TX-503) Austin/Travis County CoC', value: 'TX-503'
    value 'DALLAS_CITY_COUNTY_IRVING_COC', '(TX-600) Dallas City & County, Irving CoC', value: 'TX-600'
    value 'FORT_WORTH_ARLINGTON_TARRANT_COUNTY_COC', '(TX-601) Fort Worth, Arlington/Tarrant County CoC', value: 'TX-601'
    value 'EL_PASO_CITY_COUNTY_COC', '(TX-603) El Paso City & County CoC', value: 'TX-603'
    value 'WACO_MC_LENNAN_COUNTY_COC', '(TX-604) Waco/McLennan County CoC', value: 'TX-604'
    value 'TEXAS_BALANCE_OF_STATE_COC', '(TX-607) Texas Balance of State CoC', value: 'TX-607'
    value 'AMARILLO_COC', '(TX-611) Amarillo CoC', value: 'TX-611'
    value 'WICHITA_FALLS_WISE_PALO_PINTO_WICHITA_ARCHER_COUNTIES_COC', '(TX-624) Wichita Falls/Wise, Palo Pinto, Wichita, Archer Counties CoC', value: 'TX-624'
    value 'HOUSTON_PASADENA_CONROE_HARRIS_FT_BEND_MONTGOMERY_COUNTIES_COC', '(TX-700) Houston, Pasadena, Conroe/Harris, Ft. Bend, Montgomery Counties CoC', value: 'TX-700'
    value 'BRYAN_COLLEGE_STATION_BRAZOS_VALLEY_COC', '(TX-701) Bryan, College Station/Brazos Valley CoC', value: 'TX-701'
    value 'SALT_LAKE_CITY_COUNTY_COC', '(UT-500) Salt Lake City & County CoC', value: 'UT-500'
    value 'UTAH_BALANCE_OF_STATE_COC', '(UT-503) Utah Balance of State CoC', value: 'UT-503'
    value 'PROVO_MOUNTAINLAND_COC', '(UT-504) Provo/Mountainland CoC', value: 'UT-504'
    value 'RICHMOND_HENRICO_CHESTERFIELD_HANOVER_COUNTIES_COC', '(VA-500) Richmond/Henrico, Chesterfield, Hanover Counties CoC', value: 'VA-500'
    value 'NORFOLK_CHESAPEAKE_SUFFOLK_ISLE_OF_WIGHT_SOUTHAMPTON_COUNTIES_COC', '(VA-501) Norfolk, Chesapeake, Suffolk/Isle of Wight, Southampton Counties CoC', value: 'VA-501'
    value 'ROANOKE_CITY_COUNTY_SALEM_COC', '(VA-502) Roanoke City & County, Salem CoC', value: 'VA-502'
    value 'VIRGINIA_BEACH_COC', '(VA-503) Virginia Beach CoC', value: 'VA-503'
    value 'CHARLOTTESVILLE_COC', '(VA-504) Charlottesville CoC', value: 'VA-504'
    value 'NEWPORT_NEWS_HAMPTON_VIRGINIA_PENINSULA_COC', '(VA-505) Newport News, Hampton/Virginia Peninsula CoC', value: 'VA-505'
    value 'PORTSMOUTH_COC', '(VA-507) Portsmouth CoC', value: 'VA-507'
    value 'LYNCHBURG_COC', '(VA-508) Lynchburg CoC', value: 'VA-508'
    value 'HARRISONBURG_WINCHESTER_WESTERN_VIRGINIA_COC', '(VA-513) Harrisonburg, Winchester/Western Virginia CoC', value: 'VA-513'
    value 'FREDERICKSBURG_SPOTSYLVANIA_STAFFORD_COUNTIES_COC', '(VA-514) Fredericksburg/Spotsylvania, Stafford Counties CoC', value: 'VA-514'
    value 'VIRGINIA_BALANCE_OF_STATE_COC', '(VA-521) Virginia Balance of State CoC', value: 'VA-521'
    value 'ARLINGTON_COUNTY_COC', '(VA-600) Arlington County CoC', value: 'VA-600'
    value 'FAIRFAX_COUNTY_COC', '(VA-601) Fairfax County CoC', value: 'VA-601'
    value 'LOUDOUN_COUNTY_COC', '(VA-602) Loudoun County CoC', value: 'VA-602'
    value 'ALEXANDRIA_COC', '(VA-603) Alexandria CoC', value: 'VA-603'
    value 'PRINCE_WILLIAM_COUNTY_COC', '(VA-604) Prince William County CoC', value: 'VA-604'
    value 'VIRGIN_ISLANDS_COC', '(VI-500) Virgin Islands CoC', value: 'VI-500'
    value 'VERMONT_BALANCE_OF_STATE_COC', '(VT-500) Vermont Balance of State CoC', value: 'VT-500'
    value 'BURLINGTON_CHITTENDEN_COUNTY_COC', '(VT-501) Burlington/Chittenden County CoC', value: 'VT-501'
    value 'SEATTLE_KING_COUNTY_COC', '(WA-500) Seattle/King County CoC', value: 'WA-500'
    value 'WASHINGTON_BALANCE_OF_STATE_COC', '(WA-501) Washington Balance of State CoC', value: 'WA-501'
    value 'SPOKANE_CITY_COUNTY_COC', '(WA-502) Spokane City & County CoC', value: 'WA-502'
    value 'TACOMA_LAKEWOOD_PIERCE_COUNTY_COC', '(WA-503) Tacoma, Lakewood/Pierce County CoC', value: 'WA-503'
    value 'EVERETT_SNOHOMISH_COUNTY_COC', '(WA-504) Everett/Snohomish County CoC', value: 'WA-504'
    value 'VANCOUVER_CLARK_COUNTY_COC', '(WA-508) Vancouver/Clark County CoC', value: 'WA-508'
    value 'WISCONSIN_BALANCE_OF_STATE_COC', '(WI-500) Wisconsin Balance of State CoC', value: 'WI-500'
    value 'MILWAUKEE_CITY_COUNTY_COC', '(WI-501) Milwaukee City & County CoC', value: 'WI-501'
    value 'RACINE_CITY_COUNTY_COC', '(WI-502) Racine City & County CoC', value: 'WI-502'
    value 'MADISON_DANE_COUNTY_COC', '(WI-503) Madison/Dane County CoC', value: 'WI-503'
    value 'WHEELING_WEIRTON_AREA_COC', '(WV-500) Wheeling, Weirton Area CoC', value: 'WV-500'
    value 'HUNTINGTON_CABELL_WAYNE_COUNTIES_COC', '(WV-501) Huntington/Cabell, Wayne Counties CoC', value: 'WV-501'
    value 'CHARLESTON_KANAWHA_PUTNAM_BOONE_CLAY_COUNTIES_COC', '(WV-503) Charleston/Kanawha, Putnam, Boone, Clay Counties CoC', value: 'WV-503'
    value 'WEST_VIRGINIA_BALANCE_OF_STATE_COC', '(WV-508) West Virginia Balance of State CoC', value: 'WV-508'
    value 'WYOMING_STATEWIDE_COC', '(WY-500) Wyoming Statewide CoC', value: 'WY-500'
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class GeographyType < Types::BaseEnum
    description 'HUD GeographyType (2.03.4)'
    graphql_name 'GeographyType'
    value 'URBAN', '(1) Urban', value: 1
    value 'SUBURBAN', '(2) Suburban', value: 2
    value 'RURAL', '(3) Rural', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Unknown / data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HMISParticipationType < Types::BaseEnum
    description 'HUD HMISParticipationType (2.08.1)'
    graphql_name 'HMISParticipationType'
    value 'NOT_PARTICIPATING', '(0) Not Participating', value: 0
    value 'HMIS_PARTICIPATING', '(1) HMIS Participating', value: 1
    value 'COMPARABLE_DATABASE_PARTICIPATING', '(2) Comparable Database Participating', value: 2
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NameDataQuality < Types::BaseEnum
    description 'HUD NameDataQuality (3.01.5)'
    graphql_name 'NameDataQuality'
    value 'FULL_NAME_REPORTED', '(1) Full name reported', value: 1
    value 'PARTIAL_STREET_NAME_OR_CODE_NAME_REPORTED', '(2) Partial, street name, or code name reported', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class Destination < Types::BaseEnum
    description 'HUD Destination (3.12)'
    graphql_name 'Destination'
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'OTHER', '(17) Other', value: 17
    value 'DECEASED', '(24) Deceased', value: 24
    value 'NO_EXIT_INTERVIEW_COMPLETED', '(30) No exit interview completed', value: 30
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'EMERGENCY_SHELTER_INCLUDING_HOTEL_OR_MOTEL_PAID_FOR_WITH_EMERGENCY_SHELTER_VOUCHER_OR_HOST_HOME_SHELTER', '(101) Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter', value: 101
    value 'PLACE_NOT_MEANT_FOR_HABITATION', '(116) Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)', value: 116
    value 'SAFE_HAVEN', '(118) Safe Haven', value: 118
    value 'PSYCHIATRIC_HOSPITAL_OR_OTHER_PSYCHIATRIC_FACILITY', '(204) Psychiatric hospital or other psychiatric facility', value: 204
    value 'SUBSTANCE_ABUSE_TREATMENT_FACILITY_OR_DETOX_CENTER', '(205) Substance abuse treatment facility or detox center', value: 205
    value 'HOSPITAL_OR_OTHER_RESIDENTIAL_NON_PSYCHIATRIC_MEDICAL_FACILITY', '(206) Hospital or other residential non-psychiatric medical facility', value: 206
    value 'JAIL_PRISON_OR_JUVENILE_DETENTION_FACILITY', '(207) Jail, prison or juvenile detention facility', value: 207
    value 'FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME', '(215) Foster care home or foster care group home', value: 215
    value 'LONG_TERM_CARE_FACILITY_OR_NURSING_HOME', '(225) Long-term care facility or nursing home', value: 225
    value 'TRANSITIONAL_HOUSING_FOR_HOMELESS_PERSONS', '(302) Transitional housing for homeless persons (including homeless youth)', value: 302
    value 'STAYING_OR_LIVING_WITH_FAMILY_TEMPORARY_TENURE', '(312) Staying or living with family, temporary tenure (e.g. room, apartment or house)', value: 312
    value 'STAYING_OR_LIVING_WITH_FRIENDS_TEMPORARY_TENURE', '(313) Staying or living with friends, temporary tenure (e.g. room apartment or house)', value: 313
    value 'HOTEL_OR_MOTEL_PAID_FOR_WITHOUT_EMERGENCY_SHELTER_VOUCHER', '(314) Hotel or motel paid for without emergency shelter voucher', value: 314
    value 'MOVED_FROM_ONE_HOPWA_FUNDED_PROJECT_TO_HOPWA_TH', '(327) Moved from one HOPWA funded project to HOPWA TH', value: 327
    value 'RESIDENTIAL_PROJECT_OR_HALFWAY_HOUSE_WITH_NO_HOMELESS_CRITERIA', '(329) Residential project or halfway house with no homeless criteria', value: 329
    value 'HOST_HOME_NON_CRISIS', '(332) Host Home (non-crisis)', value: 332
    value 'RENTAL_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY', '(410) Rental by client, no ongoing housing subsidy', value: 410
    value 'OWNED_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY', '(411) Owned by client, no ongoing housing subsidy', value: 411
    value 'OWNED_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY', '(421) Owned by client, with ongoing housing subsidy', value: 421
    value 'STAYING_OR_LIVING_WITH_FAMILY_PERMANENT_TENURE', '(422) Staying or living with family, permanent tenure', value: 422
    value 'STAYING_OR_LIVING_WITH_FRIENDS_PERMANENT_TENURE', '(423) Staying or living with friends, permanent tenure', value: 423
    value 'MOVED_FROM_ONE_HOPWA_FUNDED_PROJECT_TO_HOPWA_PH', '(426) Moved from one HOPWA funded project to HOPWA PH', value: 426
    value 'RENTAL_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY', '(435) Rental by client, with ongoing housing subsidy', value: 435
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class RelationshipToHoH < Types::BaseEnum
    description 'HUD RelationshipToHoH (3.15.1)'
    graphql_name 'RelationshipToHoH'
    value 'SELF_HEAD_OF_HOUSEHOLD', '(1) Self (head of household)', value: 1
    value 'CHILD', '(2) Child', value: 2
    value 'SPOUSE_OR_PARTNER', '(3) Spouse or partner', value: 3
    value 'OTHER_RELATIVE', '(4) Other relative', value: 4
    value 'UNRELATED_HOUSEHOLD_MEMBER', '(5) Unrelated household member', value: 5
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SSNDataQuality < Types::BaseEnum
    description 'HUD SSNDataQuality (3.02.2)'
    graphql_name 'SSNDataQuality'
    value 'FULL_SSN_REPORTED', '(1) Full SSN reported', value: 1
    value 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED', '(2) Approximate or partial SSN reported', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class DOBDataQuality < Types::BaseEnum
    description 'HUD DOBDataQuality (3.03.2)'
    graphql_name 'DOBDataQuality'
    value 'FULL_DOB_REPORTED', '(1) Full DOB reported', value: 1
    value 'APPROXIMATE_OR_PARTIAL_DOB_REPORTED', '(2) Approximate or partial DOB reported', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class TimesHomelessPastThreeYears < Types::BaseEnum
    description 'HUD TimesHomelessPastThreeYears (3.917.4)'
    graphql_name 'TimesHomelessPastThreeYears'
    value 'ONE_TIME', '(1) One time', value: 1
    value 'TWO_TIMES', '(2) Two times', value: 2
    value 'THREE_TIMES', '(3) Three times', value: 3
    value 'FOUR_OR_MORE_TIMES', '(4) Four or more times', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class CurrentLivingSituation < Types::BaseEnum
    description 'HUD CurrentLivingSituation (4.12)'
    graphql_name 'CurrentLivingSituationOptions'
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'OTHER', '(17) Other', value: 17
    value 'WORKER_UNABLE_TO_DETERMINE', '(37) Worker unable to determine', value: 37
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'EMERGENCY_SHELTER_INCLUDING_HOTEL_OR_MOTEL_PAID_FOR_WITH_EMERGENCY_SHELTER_VOUCHER_OR_HOST_HOME_SHELTER', '(101) Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter', value: 101
    value 'PLACE_NOT_MEANT_FOR_HABITATION', '(116) Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)', value: 116
    value 'SAFE_HAVEN', '(118) Safe Haven', value: 118
    value 'PSYCHIATRIC_HOSPITAL_OR_OTHER_PSYCHIATRIC_FACILITY', '(204) Psychiatric hospital or other psychiatric facility', value: 204
    value 'SUBSTANCE_ABUSE_TREATMENT_FACILITY_OR_DETOX_CENTER', '(205) Substance abuse treatment facility or detox center', value: 205
    value 'HOSPITAL_OR_OTHER_RESIDENTIAL_NON_PSYCHIATRIC_MEDICAL_FACILITY', '(206) Hospital or other residential non-psychiatric medical facility', value: 206
    value 'JAIL_PRISON_OR_JUVENILE_DETENTION_FACILITY', '(207) Jail, prison or juvenile detention facility', value: 207
    value 'FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME', '(215) Foster care home or foster care group home', value: 215
    value 'LONG_TERM_CARE_FACILITY_OR_NURSING_HOME', '(225) Long-term care facility or nursing home', value: 225
    value 'TRANSITIONAL_HOUSING_FOR_HOMELESS_PERSONS', '(302) Transitional housing for homeless persons (including homeless youth)', value: 302
    value 'HOTEL_OR_MOTEL_PAID_FOR_WITHOUT_EMERGENCY_SHELTER_VOUCHER', '(314) Hotel or motel paid for without emergency shelter voucher', value: 314
    value 'RESIDENTIAL_PROJECT_OR_HALFWAY_HOUSE_WITH_NO_HOMELESS_CRITERIA', '(329) Residential project or halfway house with no homeless criteria', value: 329
    value 'HOST_HOME_NON_CRISIS', '(332) Host Home (non-crisis)', value: 332
    value 'STAYING_OR_LIVING_IN_A_FAMILY_MEMBER_S_ROOM_APARTMENT_OR_HOUSE', '(335) Staying or living in a family member’s room, apartment, or house', value: 335
    value 'STAYING_OR_LIVING_IN_A_FRIEND_S_ROOM_APARTMENT_OR_HOUSE', "(336) Staying or living in a friend's room, apartment or house", value: 336
    value 'RENTAL_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY', '(410) Rental by client, no ongoing housing subsidy', value: 410
    value 'OWNED_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY', '(411) Owned by client, no ongoing housing subsidy', value: 411
    value 'OWNED_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY', '(421) Owned by client, with ongoing housing subsidy', value: 421
    value 'RENTAL_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY', '(435) Rental by client, with ongoing housing subsidy', value: 435
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PriorLivingSituation < Types::BaseEnum
    description 'HUD PriorLivingSituation (3.917)'
    graphql_name 'PriorLivingSituation'
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'EMERGENCY_SHELTER_INCLUDING_HOTEL_OR_MOTEL_PAID_FOR_WITH_EMERGENCY_SHELTER_VOUCHER_OR_HOST_HOME_SHELTER', '(101) Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter', value: 101
    value 'PLACE_NOT_MEANT_FOR_HABITATION', '(116) Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)', value: 116
    value 'SAFE_HAVEN', '(118) Safe Haven', value: 118
    value 'PSYCHIATRIC_HOSPITAL_OR_OTHER_PSYCHIATRIC_FACILITY', '(204) Psychiatric hospital or other psychiatric facility', value: 204
    value 'SUBSTANCE_ABUSE_TREATMENT_FACILITY_OR_DETOX_CENTER', '(205) Substance abuse treatment facility or detox center', value: 205
    value 'HOSPITAL_OR_OTHER_RESIDENTIAL_NON_PSYCHIATRIC_MEDICAL_FACILITY', '(206) Hospital or other residential non-psychiatric medical facility', value: 206
    value 'JAIL_PRISON_OR_JUVENILE_DETENTION_FACILITY', '(207) Jail, prison or juvenile detention facility', value: 207
    value 'FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME', '(215) Foster care home or foster care group home', value: 215
    value 'LONG_TERM_CARE_FACILITY_OR_NURSING_HOME', '(225) Long-term care facility or nursing home', value: 225
    value 'TRANSITIONAL_HOUSING_FOR_HOMELESS_PERSONS', '(302) Transitional housing for homeless persons (including homeless youth)', value: 302
    value 'HOTEL_OR_MOTEL_PAID_FOR_WITHOUT_EMERGENCY_SHELTER_VOUCHER', '(314) Hotel or motel paid for without emergency shelter voucher', value: 314
    value 'RESIDENTIAL_PROJECT_OR_HALFWAY_HOUSE_WITH_NO_HOMELESS_CRITERIA', '(329) Residential project or halfway house with no homeless criteria', value: 329
    value 'HOST_HOME_NON_CRISIS', '(332) Host Home (non-crisis)', value: 332
    value 'STAYING_OR_LIVING_IN_A_FAMILY_MEMBER_S_ROOM_APARTMENT_OR_HOUSE', '(335) Staying or living in a family member’s room, apartment, or house', value: 335
    value 'STAYING_OR_LIVING_IN_A_FRIEND_S_ROOM_APARTMENT_OR_HOUSE', "(336) Staying or living in a friend's room, apartment or house", value: 336
    value 'RENTAL_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY', '(410) Rental by client, no ongoing housing subsidy', value: 410
    value 'OWNED_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY', '(411) Owned by client, no ongoing housing subsidy', value: 411
    value 'OWNED_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY', '(421) Owned by client, with ongoing housing subsidy', value: 421
    value 'RENTAL_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY', '(435) Rental by client, with ongoing housing subsidy', value: 435
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class RentalSubsidyType < Types::BaseEnum
    description 'HUD RentalSubsidyType (3.12.A)'
    graphql_name 'RentalSubsidyType'
    value 'GPD_TIP_HOUSING_SUBSIDY', '(428) GPD TIP housing subsidy', value: 428
    value 'VASH_HOUSING_SUBSIDY', '(419) VASH housing subsidy', value: 419
    value 'RRH_OR_EQUIVALENT_SUBSIDY', '(431) RRH or equivalent subsidy', value: 431
    value 'HCV_VOUCHER', '(433) HCV voucher (tenant or project based) (not dedicated)', value: 433
    value 'PUBLIC_HOUSING_UNIT', '(434) Public housing unit', value: 434
    value 'RENTAL_BY_CLIENT_WITH_OTHER_ONGOING_HOUSING_SUBSIDY', '(420) Rental by client, with other ongoing housing subsidy', value: 420
    value 'HOUSING_STABILITY_VOUCHER', '(436) Housing Stability Voucher', value: 436
    value 'FAMILY_UNIFICATION_PROGRAM_VOUCHER_FUP', '(437) Family Unification Program Voucher (FUP)', value: 437
    value 'FOSTER_YOUTH_TO_INDEPENDENCE_INITIATIVE_FYI', '(438) Foster Youth to Independence Initiative (FYI)', value: 438
    value 'PERMANENT_SUPPORTIVE_HOUSING', '(439) Permanent Supportive Housing', value: 439
    value 'OTHER_PERMANENT_HOUSING_DEDICATED_FOR_FORMERLY_HOMELESS_PERSONS', '(440) Other permanent housing dedicated for formerly homeless persons', value: 440
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ResidencePriorLengthOfStay < Types::BaseEnum
    description 'HUD ResidencePriorLengthOfStay (3.917.2)'
    graphql_name 'ResidencePriorLengthOfStay'
    value 'ONE_WEEK_OR_MORE_BUT_LESS_THAN_ONE_MONTH', '(2) One week or more, but less than one month', value: 2
    value 'ONE_MONTH_OR_MORE_BUT_LESS_THAN_90_DAYS', '(3) One month or more, but less than 90 days', value: 3
    value 'NUM_90_DAYS_OR_MORE_BUT_LESS_THAN_ONE_YEAR', '(4) 90 days or more but less than one year', value: 4
    value 'ONE_YEAR_OR_LONGER', '(5) One year or longer', value: 5
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'ONE_NIGHT_OR_LESS', '(10) One night or less', value: 10
    value 'TWO_TO_SIX_NIGHTS', '(11) Two to six nights', value: 11
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class MonthsHomelessPastThreeYears < Types::BaseEnum
    description 'HUD MonthsHomelessPastThreeYears (3.917.5)'
    graphql_name 'MonthsHomelessPastThreeYears'
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'NUM_1', '(101) 1', value: 101
    value 'NUM_2', '(102) 2', value: 102
    value 'NUM_3', '(103) 3', value: 103
    value 'NUM_4', '(104) 4', value: 104
    value 'NUM_5', '(105) 5', value: 105
    value 'NUM_6', '(106) 6', value: 106
    value 'NUM_7', '(107) 7', value: 107
    value 'NUM_8', '(108) 8', value: 108
    value 'NUM_9', '(109) 9', value: 109
    value 'NUM_10', '(110) 10', value: 110
    value 'NUM_11', '(111) 11', value: 111
    value 'NUM_12', '(112) 12', value: 112
    value 'MORE_THAN_12_MONTHS', '(113) More than 12 months', value: 113
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ReasonNotInsured < Types::BaseEnum
    description 'HUD ReasonNotInsured (4.04.A)'
    graphql_name 'ReasonNotInsured'
    value 'APPLIED_DECISION_PENDING', '(1) Applied; decision pending', value: 1
    value 'APPLIED_CLIENT_NOT_ELIGIBLE', '(2) Applied; client not eligible', value: 2
    value 'CLIENT_DID_NOT_APPLY', '(3) Client did not apply', value: 3
    value 'INSURANCE_TYPE_N_A_FOR_THIS_CLIENT', '(4) Insurance type N/A for this client', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class DisabilityResponse < Types::BaseEnum
    description 'HUD DisabilityResponse (4.10.2)'
    graphql_name 'DisabilityResponse'
    value 'NO', '(0) No', value: 0
    value 'ALCOHOL_USE_DISORDER', '(1) Alcohol use disorder', value: 1
    value 'DRUG_USE_DISORDER', '(2) Drug use disorder', value: 2
    value 'BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS', '(3) Both alcohol and drug use disorders', value: 3
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class WhenDVOccurred < Types::BaseEnum
    description 'HUD WhenDVOccurred (4.11.A)'
    graphql_name 'WhenDVOccurred'
    value 'WITHIN_THE_PAST_THREE_MONTHS', '(1) Within the past three months', value: 1
    value 'THREE_TO_SIX_MONTHS_AGO', '(2) Three to six months ago (excluding six months exactly)', value: 2
    value 'SIX_MONTHS_TO_ONE_YEAR_AGO', '(3) Six months to one year ago (excluding one year exactly)', value: 3
    value 'ONE_YEAR_OR_MORE', '(4) One year or more', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class BedNight < Types::BaseEnum
    description 'HUD BedNight (4.14)'
    graphql_name 'BedNight'
    value 'BED_NIGHT', '(200) Bed Night', value: 200
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class RHYServices < Types::BaseEnum
    description 'HUD RHYServices (R14.2)'
    graphql_name 'RHYServices'
    value 'COMMUNITY_SERVICE_SERVICE_LEARNING_CSL', '(2) Community service/service learning (CSL)', value: 2
    value 'EDUCATION', '(5) Education', value: 5
    value 'EMPLOYMENT_AND_TRAINING_SERVICES', '(6) Employment and training services', value: 6
    value 'CRIMINAL_JUSTICE_LEGAL_SERVICES', '(7) Criminal justice /legal services', value: 7
    value 'LIFE_SKILLS_TRAINING', '(8) Life skills training', value: 8
    value 'PARENTING_EDUCATION_FOR_YOUTH_WITH_CHILDREN', '(10) Parenting education for youth with children', value: 10
    value 'POST_NATAL_CARE_FOR_CLIENT', '(12) Post-natal care for client (person who gave birth)', value: 12
    value 'PRE_NATAL_CARE', '(13) Pre-natal care', value: 13
    value 'HEALTH_MEDICAL_CARE', '(14) Health/medical care', value: 14
    value 'SUBSTANCE_USE_DISORDER_TREATMENT', '(17) Substance use disorder treatment', value: 17
    value 'SUBSTANCE_USE_DISORDER_PREVENTION_SERVICES', '(18) Substance use disorder/Prevention Services', value: 18
    value 'HOME_BASED_SERVICES', '(26) Home-based Services', value: 26
    value 'POST_NATAL_NEWBORN_CARE', '(27) Post-natal newborn care (wellness exams; immunizations)', value: 27
    value 'STD_TESTING', '(28) STD Testing', value: 28
    value 'STREET_BASED_SERVICES', '(29) Street-based Services', value: 29
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SSVFFinancialAssistance < Types::BaseEnum
    description 'HUD SSVFFinancialAssistance (V3.3)'
    graphql_name 'SSVFFinancialAssistance'
    value 'RENTAL_ASSISTANCE', '(1) Rental assistance', value: 1
    value 'SECURITY_DEPOSIT', '(2) Security deposit', value: 2
    value 'UTILITY_DEPOSIT', '(3) Utility deposit', value: 3
    value 'UTILITY_FEE_PAYMENT_ASSISTANCE', '(4) Utility fee payment assistance', value: 4
    value 'MOVING_COSTS', '(5) Moving costs', value: 5
    value 'TRANSPORTATION_SERVICES_TOKENS_VOUCHERS', '(8) Transportation services: tokens/vouchers', value: 8
    value 'TRANSPORTATION_SERVICES_VEHICLE_REPAIR_MAINTENANCE', '(9) Transportation services: vehicle repair/maintenance', value: 9
    value 'CHILD_CARE', '(10) Child care', value: 10
    value 'GENERAL_HOUSING_STABILITY_ASSISTANCE_EMERGENCY_SUPPLIES_DEPRECATED', '(11) General housing stability assistance - emergency supplies [Deprecated]', value: 11
    value 'GENERAL_HOUSING_STABILITY_ASSISTANCE', '(12) General housing stability assistance', value: 12
    value 'EMERGENCY_HOUSING_ASSISTANCE', '(14) Emergency housing assistance', value: 14
    value 'SHALLOW_SUBSIDY_FINANCIAL_ASSISTANCE', '(15) Shallow Subsidy - Financial Assistance', value: 15
    value 'FOOD_ASSISTANCE', '(16) Food Assistance', value: 16
    value 'LANDLORD_INCENTIVE', '(17) Landlord Incentive', value: 17
    value 'TENANT_INCENTIVE', '(18) Tenant Incentive', value: 18
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class AssessmentType < Types::BaseEnum
    description 'HUD AssessmentType (4.19.3)'
    graphql_name 'AssessmentType'
    value 'PHONE', '(1) Phone', value: 1
    value 'VIRTUAL', '(2) Virtual', value: 2
    value 'IN_PERSON', '(3) In Person', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class AssessmentLevel < Types::BaseEnum
    description 'HUD AssessmentLevel (4.19.4)'
    graphql_name 'AssessmentLevel'
    value 'CRISIS_NEEDS_ASSESSMENT', '(1) Crisis Needs Assessment', value: 1
    value 'HOUSING_NEEDS_ASSESSMENT', '(2) Housing Needs Assessment', value: 2
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PrioritizationStatus < Types::BaseEnum
    description 'HUD PrioritizationStatus (4.19.7)'
    graphql_name 'PrioritizationStatus'
    value 'PLACED_ON_PRIORITIZATION_LIST', '(1) Placed on prioritization list', value: 1
    value 'NOT_PLACED_ON_PRIORITIZATION_LIST', '(2) Not placed on prioritization list', value: 2
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class EventType < Types::BaseEnum
    description 'HUD EventType (4.20.2)'
    graphql_name 'EventType'
    value 'REFERRAL_TO_PREVENTION_ASSISTANCE_PROJECT', '(1) Referral to Prevention Assistance project', value: 1
    value 'PROBLEM_SOLVING_DIVERSION_RAPID_RESOLUTION_INTERVENTION_OR_SERVICE', '(2) Problem Solving/Diversion/Rapid Resolution intervention or service', value: 2
    value 'REFERRAL_TO_SCHEDULED_COORDINATED_ENTRY_CRISIS_NEEDS_ASSESSMENT', '(3) Referral to scheduled Coordinated Entry Crisis Needs Assessment', value: 3
    value 'REFERRAL_TO_SCHEDULED_COORDINATED_ENTRY_HOUSING_NEEDS_ASSESSMENT', '(4) Referral to scheduled Coordinated Entry Housing Needs Assessment', value: 4
    value 'REFERRAL_TO_POST_PLACEMENT_FOLLOW_UP_CASE_MANAGEMENT', '(5) Referral to Post-placement/ follow-up case management', value: 5
    value 'REFERRAL_TO_STREET_OUTREACH_PROJECT_OR_SERVICES', '(6) Referral to Street Outreach project or services', value: 6
    value 'REFERRAL_TO_HOUSING_NAVIGATION_PROJECT_OR_SERVICES', '(7) Referral to Housing Navigation project or services', value: 7
    value 'REFERRAL_TO_NON_CONTINUUM_SERVICES_INELIGIBLE_FOR_CONTINUUM_SERVICES', '(8) Referral to Non-continuum services: Ineligible for continuum services', value: 8
    value 'REFERRAL_TO_NON_CONTINUUM_SERVICES_NO_AVAILABILITY_IN_CONTINUUM_SERVICES', '(9) Referral to Non-continuum services: No availability in continuum services', value: 9
    value 'REFERRAL_TO_EMERGENCY_SHELTER_BED_OPENING', '(10) Referral to Emergency Shelter bed opening', value: 10
    value 'REFERRAL_TO_TRANSITIONAL_HOUSING_BED_UNIT_OPENING', '(11) Referral to Transitional Housing bed/unit opening', value: 11
    value 'REFERRAL_TO_JOINT_TH_RRH_PROJECT_UNIT_RESOURCE_OPENING', '(12) Referral to Joint TH-RRH project/unit/resource opening', value: 12
    value 'REFERRAL_TO_RRH_PROJECT_RESOURCE_OPENING', '(13) Referral to RRH project resource opening', value: 13
    value 'REFERRAL_TO_PSH_PROJECT_RESOURCE_OPENING', '(14) Referral to PSH project resource opening', value: 14
    value 'REFERRAL_TO_OTHER_PH_PROJECT_UNIT_RESOURCE_OPENING', '(15) Referral to Other PH project/unit/resource opening', value: 15
    value 'REFERRAL_TO_EMERGENCY_ASSISTANCE_FLEX_FUND_FURNITURE_ASSISTANCE', '(16) Referral to emergency assistance/flex fund/furniture assistance', value: 16
    value 'REFERRAL_TO_EMERGENCY_HOUSING_VOUCHER_EHV', '(17) Referral to Emergency Housing Voucher (EHV)', value: 17
    value 'REFERRAL_TO_A_HOUSING_STABILITY_VOUCHER', '(18) Referral to a Housing Stability Voucher', value: 18
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ReferralResult < Types::BaseEnum
    description 'HUD ReferralResult (4.20.D)'
    graphql_name 'ReferralResult'
    value 'SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED', '(1) Successful referral: client accepted', value: 1
    value 'UNSUCCESSFUL_REFERRAL_CLIENT_REJECTED', '(2) Unsuccessful referral: client rejected', value: 2
    value 'UNSUCCESSFUL_REFERRAL_PROVIDER_REJECTED', '(3) Unsuccessful referral: provider rejected', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class EarlyExitReason < Types::BaseEnum
    description 'HUD EarlyExitReason (R17.A)'
    graphql_name 'EarlyExitReason'
    value 'LEFT_FOR_OTHER_OPPORTUNITIES_INDEPENDENT_LIVING', '(1) Left for other opportunities - independent living', value: 1
    value 'LEFT_FOR_OTHER_OPPORTUNITIES_EDUCATION', '(2) Left for other opportunities - education', value: 2
    value 'LEFT_FOR_OTHER_OPPORTUNITIES_MILITARY', '(3) Left for other opportunities - military', value: 3
    value 'LEFT_FOR_OTHER_OPPORTUNITIES_OTHER', '(4) Left for other opportunities - other', value: 4
    value 'NEEDS_COULD_NOT_BE_MET_BY_PROJECT', '(5) Needs could not be met by project', value: 5
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class DataCollectionStage < Types::BaseEnum
    description 'HUD DataCollectionStage (5.03.1)'
    graphql_name 'DataCollectionStage'
    value 'PROJECT_ENTRY', '(1) Project entry', value: 1
    value 'UPDATE', '(2) Update', value: 2
    value 'PROJECT_EXIT', '(3) Project exit', value: 3
    value 'ANNUAL_ASSESSMENT', '(5) Annual assessment', value: 5
    value 'POST_EXIT', '(6) Post-exit', value: 6
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class MovingOnAssistance < Types::BaseEnum
    description 'HUD MovingOnAssistance (C2.2)'
    graphql_name 'MovingOnAssistance'
    value 'SUBSIDIZED_HOUSING_APPLICATION_ASSISTANCE', '(1) Subsidized housing application assistance', value: 1
    value 'FINANCIAL_ASSISTANCE_FOR_MOVING_ON', '(2) Financial assistance for Moving On (e.g., security deposit, moving expenses)', value: 2
    value 'NON_FINANCIAL_ASSISTANCE_FOR_MOVING_ON', '(3) Non-financial assistance for Moving On (e.g., housing navigation, transition support)', value: 3
    value 'HOUSING_REFERRAL_PLACEMENT', '(4) Housing referral/placement', value: 4
    value 'OTHER', '(5) Other', value: 5
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class CurrentSchoolAttended < Types::BaseEnum
    description 'HUD CurrentSchoolAttended (C3.2)'
    graphql_name 'CurrentSchoolAttended'
    value 'NOT_CURRENTLY_ENROLLED_IN_ANY_SCHOOL_OR_EDUCATIONAL_COURSE', '(0) Not currently enrolled in any school or educational course', value: 0
    value 'CURRENTLY_ENROLLED_BUT_NOT_ATTENDING_REGULARLY', '(1) Currently enrolled but NOT attending regularly (when school or the course is in session)', value: 1
    value 'CURRENTLY_ENROLLED_AND_ATTENDING_REGULARLY', '(2) Currently enrolled and attending regularly (when school or the course is in session)', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class MostRecentEdStatus < Types::BaseEnum
    description 'HUD MostRecentEdStatus (C3.A)'
    graphql_name 'MostRecentEdStatus'
    value 'K12_GRADUATED_FROM_HIGH_SCHOOL', '(0) K12: Graduated from high school', value: 0
    value 'K12_OBTAINED_GED', '(1) K12: Obtained GED', value: 1
    value 'K12_DROPPED_OUT', '(2) K12: Dropped out', value: 2
    value 'K12_SUSPENDED', '(3) K12: Suspended', value: 3
    value 'K12_EXPELLED', '(4) K12: Expelled', value: 4
    value 'HIGHER_EDUCATION_PURSUING_A_CREDENTIAL_BUT_NOT_CURRENTLY_ATTENDING', '(5) Higher education: Pursuing a credential but not currently attending', value: 5
    value 'HIGHER_EDUCATION_DROPPED_OUT', '(6) Higher education: Dropped out', value: 6
    value 'HIGHER_EDUCATION_OBTAINED_A_CREDENTIAL_DEGREE', '(7) Higher education: Obtained a credential/degree', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class CurrentEdStatus < Types::BaseEnum
    description 'HUD CurrentEdStatus (C3.B)'
    graphql_name 'CurrentEdStatus'
    value 'PURSUING_A_HIGH_SCHOOL_DIPLOMA_OR_GED', '(0) Pursuing a high school diploma or GED', value: 0
    value 'PURSUING_ASSOCIATE_S_DEGREE', "(1) Pursuing Associate's Degree", value: 1
    value 'PURSUING_BACHELOR_S_DEGREE', "(2) Pursuing Bachelor's Degree", value: 2
    value 'PURSUING_GRADUATE_DEGREE', '(3) Pursuing Graduate Degree', value: 3
    value 'PURSUING_OTHER_POST_SECONDARY_CREDENTIAL', '(4) Pursuing other post-secondary credential', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PATHServices < Types::BaseEnum
    description 'HUD PATHServices (P1.2)'
    graphql_name 'PATHServices'
    value 'RE_ENGAGEMENT', '(1) Re-engagement', value: 1
    value 'SCREENING', '(2) Screening', value: 2
    value 'HABILITATION_REHABILITATION', '(3) Habilitation/rehabilitation', value: 3
    value 'COMMUNITY_MENTAL_HEALTH', '(4) Community mental health', value: 4
    value 'SUBSTANCE_USE_TREATMENT', '(5) Substance use treatment', value: 5
    value 'CASE_MANAGEMENT', '(6) Case management', value: 6
    value 'RESIDENTIAL_SUPPORTIVE_SERVICES', '(7) Residential supportive services', value: 7
    value 'HOUSING_MINOR_RENOVATION', '(8) Housing minor renovation', value: 8
    value 'HOUSING_MOVING_ASSISTANCE', '(9) Housing moving assistance', value: 9
    value 'HOUSING_ELIGIBILITY_DETERMINATION', '(10) Housing eligibility determination', value: 10
    value 'SECURITY_DEPOSITS', '(11) Security deposits', value: 11
    value 'ONE_TIME_RENT_FOR_EVICTION_PREVENTION', '(12) One-time rent for eviction prevention', value: 12
    value 'CLINICAL_ASSESSMENT', '(14) Clinical assessment', value: 14
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PATHReferral < Types::BaseEnum
    description 'HUD PATHReferral (P2.2)'
    graphql_name 'PATHReferral'
    value 'COMMUNITY_MENTAL_HEALTH', '(1) Community mental health', value: 1
    value 'SUBSTANCE_USE_TREATMENT', '(2) Substance use treatment', value: 2
    value 'PRIMARY_HEALTH_DENTAL_CARE', '(3) Primary health/dental care', value: 3
    value 'JOB_TRAINING', '(4) Job training', value: 4
    value 'EDUCATIONAL_SERVICES', '(5) Educational services', value: 5
    value 'HOUSING_SERVICES', '(6) Housing services', value: 6
    value 'PERMANENT_HOUSING', '(7) Permanent housing', value: 7
    value 'INCOME_ASSISTANCE', '(8) Income assistance', value: 8
    value 'EMPLOYMENT_ASSISTANCE', '(9) Employment assistance', value: 9
    value 'MEDICAL_INSURANCE', '(10) Medical insurance', value: 10
    value 'TEMPORARY_HOUSING', '(11) Temporary housing', value: 11
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PATHReferralOutcome < Types::BaseEnum
    description 'HUD PATHReferralOutcome (P2.A)'
    graphql_name 'PATHReferralOutcome'
    value 'ATTAINED', '(1) Attained', value: 1
    value 'NOT_ATTAINED', '(2) Not attained', value: 2
    value 'UNKNOWN', '(3) Unknown', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ReasonNotEnrolled < Types::BaseEnum
    description 'HUD ReasonNotEnrolled (P3.A)'
    graphql_name 'ReasonNotEnrolled'
    value 'CLIENT_WAS_FOUND_INELIGIBLE_FOR_PATH', '(1) Client was found ineligible for PATH', value: 1
    value 'CLIENT_WAS_NOT_ENROLLED_FOR_OTHER_REASON_S', '(2) Client was not enrolled for other reason(s)', value: 2
    value 'UNABLE_TO_LOCATE_CLIENT', '(3) Unable to locate client', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ReferralSource < Types::BaseEnum
    description 'HUD ReferralSource (R1.1)'
    graphql_name 'ReferralSource'
    value 'SELF_REFERRAL', '(1) Self-referral', value: 1
    value 'INDIVIDUAL_PARENT_GUARDIAN_RELATIVE_FRIEND_FOSTER_PARENT_OTHER_INDIVIDUAL', '(2) Individual: Parent/Guardian/Relative/Friend/Foster Parent/Other Individual', value: 2
    value 'OUTREACH_PROJECT', '(7) Outreach Project', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'TEMPORARY_SHELTER', '(11) Temporary Shelter', value: 11
    value 'RESIDENTIAL_PROJECT', '(18) Residential Project', value: 18
    value 'HOTLINE', '(28) Hotline', value: 28
    value 'CHILD_WELFARE_CPS', '(30) Child Welfare/CPS', value: 30
    value 'JUVENILE_JUSTICE', '(34) Juvenile Justice', value: 34
    value 'LAW_ENFORCEMENT_POLICE', '(35) Law Enforcement/Police', value: 35
    value 'MENTAL_HOSPITAL', '(37) Mental Hospital', value: 37
    value 'SCHOOL', '(38) School', value: 38
    value 'OTHER_ORGANIZATION', '(39) Other organization', value: 39
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class RHYNumberofYears < Types::BaseEnum
    description 'HUD RHYNumberofYears (R11.A)'
    graphql_name 'RHYNumberofYears'
    value 'LESS_THAN_ONE_YEAR', '(1) Less than one year', value: 1
    value 'NUM_1_TO_2_YEARS', '(2) 1 to 2 years', value: 2
    value 'NUM_3_TO_5_OR_MORE_YEARS', '(3) 3 to 5 or more years', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class CountExchangeForSex < Types::BaseEnum
    description 'HUD CountExchangeForSex (R15.B)'
    graphql_name 'CountExchangeForSex'
    value 'NUM_1_3', '(1) 1-3', value: 1
    value 'NUM_4_7', '(2) 4-7', value: 2
    value 'NUM_8_11', '(3) 8-11', value: 3
    value 'NUM_12_OR_MORE', '(4) 12 or more', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ProjectCompletionStatus < Types::BaseEnum
    description 'HUD ProjectCompletionStatus (R17.1)'
    graphql_name 'ProjectCompletionStatus'
    value 'COMPLETED_PROJECT', '(1) Completed project', value: 1
    value 'CLIENT_VOLUNTARILY_LEFT_EARLY', '(2) Client voluntarily left early', value: 2
    value 'CLIENT_WAS_EXPELLED_OR_OTHERWISE_INVOLUNTARILY_DISCHARGED_FROM_PROJECT', '(3) Client was expelled or otherwise involuntarily discharged from project', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ExpelledReason < Types::BaseEnum
    description 'HUD ExpelledReason (R17.A)'
    graphql_name 'ExpelledReason'
    value 'CRIMINAL_ACTIVITY_DESTRUCTION_OF_PROPERTY_VIOLENCE', '(1) Criminal activity/destruction of property/violence', value: 1
    value 'NON_COMPLIANCE_WITH_PROJECT_RULES', '(2) Non-compliance with project rules', value: 2
    value 'NON_PAYMENT_OF_RENT_OCCUPANCY_CHARGE', '(3) Non-payment of rent/occupancy charge', value: 3
    value 'REACHED_MAXIMUM_TIME_ALLOWED_BY_PROJECT', '(4) Reached maximum time allowed by project', value: 4
    value 'PROJECT_TERMINATED', '(5) Project terminated', value: 5
    value 'UNKNOWN_DISAPPEARED', '(6) Unknown/disappeared', value: 6
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class WorkerResponse < Types::BaseEnum
    description 'HUD WorkerResponse (R19.A)'
    graphql_name 'WorkerResponse'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'WORKER_DOES_NOT_KNOW', '(2) Worker does not know', value: 2
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ReasonNoServices < Types::BaseEnum
    description 'HUD ReasonNoServices (R2.A)'
    graphql_name 'ReasonNoServices'
    value 'OUT_OF_AGE_RANGE', '(1) Out of age range', value: 1
    value 'WARD_OF_THE_STATE', '(2) Ward of the state', value: 2
    value 'WARD_OF_THE_CRIMINAL_JUSTICE_SYSTEM', '(3) Ward of the criminal justice system', value: 3
    value 'OTHER', '(4) Other', value: 4
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class AftercareProvided < Types::BaseEnum
    description 'HUD AftercareProvided (R20.2)'
    graphql_name 'AftercareProvided'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SexualOrientation < Types::BaseEnum
    description 'HUD SexualOrientation (R3.1)'
    graphql_name 'SexualOrientation'
    value 'HETEROSEXUAL', '(1) Heterosexual', value: 1
    value 'GAY', '(2) Gay', value: 2
    value 'LESBIAN', '(3) Lesbian', value: 3
    value 'BISEXUAL', '(4) Bisexual', value: 4
    value 'QUESTIONING_UNSURE', '(5) Questioning / unsure', value: 5
    value 'OTHER', '(6) Other', value: 6
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class LastGradeCompleted < Types::BaseEnum
    description 'HUD LastGradeCompleted (R4.1)'
    graphql_name 'LastGradeCompleted'
    value 'LESS_THAN_GRADE_5', '(1) Less than grade 5', value: 1
    value 'GRADES_5_6', '(2) Grades 5-6', value: 2
    value 'GRADES_7_8', '(3) Grades 7-8', value: 3
    value 'GRADES_9_11', '(4) Grades 9-11', value: 4
    value 'GRADE_12', '(5) Grade 12', value: 5
    value 'SCHOOL_PROGRAM_DOES_NOT_HAVE_GRADE_LEVELS', '(6) School program does not have grade levels', value: 6
    value 'GED', '(7) GED', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'SOME_COLLEGE', '(10) Some college', value: 10
    value 'ASSOCIATE_S_DEGREE', "(11) Associate's degree", value: 11
    value 'BACHELOR_S_DEGREE', "(12) Bachelor's degree", value: 12
    value 'GRADUATE_DEGREE', '(13) Graduate degree', value: 13
    value 'VOCATIONAL_CERTIFICATION', '(14) Vocational certification', value: 14
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SchoolStatus < Types::BaseEnum
    description 'HUD SchoolStatus (R5.1)'
    graphql_name 'SchoolStatus'
    value 'ATTENDING_SCHOOL_REGULARLY', '(1) Attending school regularly', value: 1
    value 'ATTENDING_SCHOOL_IRREGULARLY', '(2) Attending school irregularly', value: 2
    value 'GRADUATED_FROM_HIGH_SCHOOL', '(3) Graduated from high school', value: 3
    value 'OBTAINED_GED', '(4) Obtained GED', value: 4
    value 'DROPPED_OUT', '(5) Dropped out', value: 5
    value 'SUSPENDED', '(6) Suspended', value: 6
    value 'EXPELLED', '(7) Expelled', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class EmploymentType < Types::BaseEnum
    description 'HUD EmploymentType (R6.A)'
    graphql_name 'EmploymentType'
    value 'FULL_TIME', '(1) Full-time', value: 1
    value 'PART_TIME', '(2) Part-time', value: 2
    value 'SEASONAL_SPORADIC', '(3) Seasonal / sporadic (including day labor)', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NotEmployedReason < Types::BaseEnum
    description 'HUD NotEmployedReason (R6.B)'
    graphql_name 'NotEmployedReason'
    value 'LOOKING_FOR_WORK', '(1) Looking for work', value: 1
    value 'UNABLE_TO_WORK', '(2) Unable to work', value: 2
    value 'NOT_LOOKING_FOR_WORK', '(3) Not looking for work', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HealthStatus < Types::BaseEnum
    description 'HUD HealthStatus (R7.1)'
    graphql_name 'HealthStatus'
    value 'EXCELLENT', '(1) Excellent', value: 1
    value 'VERY_GOOD', '(2) Very good', value: 2
    value 'GOOD', '(3) Good', value: 3
    value 'FAIR', '(4) Fair', value: 4
    value 'POOR', '(5) Poor', value: 5
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class MilitaryBranch < Types::BaseEnum
    description 'HUD MilitaryBranch (V1.11)'
    graphql_name 'MilitaryBranch'
    value 'ARMY', '(1) Army', value: 1
    value 'AIR_FORCE', '(2) Air Force', value: 2
    value 'NAVY', '(3) Navy', value: 3
    value 'MARINES', '(4) Marines', value: 4
    value 'COAST_GUARD', '(6) Coast Guard', value: 6
    value 'SPACE_FORCE', '(7) Space Force', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class DischargeStatus < Types::BaseEnum
    description 'HUD DischargeStatus (V1.12)'
    graphql_name 'DischargeStatus'
    value 'HONORABLE', '(1) Honorable', value: 1
    value 'GENERAL_UNDER_HONORABLE_CONDITIONS', '(2) General under honorable conditions', value: 2
    value 'BAD_CONDUCT', '(4) Bad conduct', value: 4
    value 'DISHONORABLE', '(5) Dishonorable', value: 5
    value 'UNDER_OTHER_THAN_HONORABLE_CONDITIONS_OTH', '(6) Under other than honorable conditions (OTH)', value: 6
    value 'UNCHARACTERIZED', '(7) Uncharacterized', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SSVFServices < Types::BaseEnum
    description 'HUD SSVFServices (V2.2)'
    graphql_name 'SSVFServices'
    value 'OUTREACH_SERVICES', '(1) Outreach services', value: 1
    value 'CASE_MANAGEMENT_SERVICES', '(2) Case management services', value: 2
    value 'ASSISTANCE_OBTAINING_VA_BENEFITS', '(3) Assistance obtaining VA benefits', value: 3
    value 'ASSISTANCE_OBTAINING_COORDINATING_OTHER_PUBLIC_BENEFITS', '(4) Assistance obtaining/coordinating other public benefits', value: 4
    value 'DIRECT_PROVISION_OF_OTHER_PUBLIC_BENEFITS', '(5) Direct provision of other public benefits', value: 5
    value 'OTHER_NON_TFA_SUPPORTIVE_SERVICE_APPROVED_BY_VA', '(6) Other (non-TFA) supportive service approved by VA', value: 6
    value 'SHALLOW_SUBSIDY', '(7) Shallow Subsidy', value: 7
    value 'RETURNING_HOME', '(8) Returning Home', value: 8
    value 'RAPID_RESOLUTION', '(9) Rapid Resolution', value: 9
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HOPWAFinancialAssistance < Types::BaseEnum
    description 'HUD HOPWAFinancialAssistance (V2.3)'
    graphql_name 'HOPWAFinancialAssistance'
    value 'RENTAL_ASSISTANCE', '(1) Rental assistance', value: 1
    value 'SECURITY_DEPOSITS', '(2) Security deposits', value: 2
    value 'UTILITY_DEPOSITS', '(3) Utility deposits', value: 3
    value 'UTILITY_PAYMENTS', '(4) Utility payments', value: 4
    value 'MORTGAGE_ASSISTANCE', '(7) Mortgage assistance', value: 7
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SSVFSubType3 < Types::BaseEnum
    description 'HUD SSVFSubType3 (V2.A)'
    graphql_name 'SSVFSubType3'
    value 'VA_VOCATIONAL_AND_REHABILITATION_COUNSELING', '(1) VA vocational and rehabilitation counseling', value: 1
    value 'EMPLOYMENT_AND_TRAINING_SERVICES', '(2) Employment and training services', value: 2
    value 'EDUCATIONAL_ASSISTANCE', '(3) Educational assistance', value: 3
    value 'HEALTH_CARE_SERVICES', '(4) Health care services', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SSVFSubType4 < Types::BaseEnum
    description 'HUD SSVFSubType4 (V2.B)'
    graphql_name 'SSVFSubType4'
    value 'HEALTH_CARE_SERVICES', '(1) Health care services', value: 1
    value 'DAILY_LIVING_SERVICES', '(2) Daily living services', value: 2
    value 'PERSONAL_FINANCIAL_PLANNING_SERVICES', '(3) Personal financial planning services', value: 3
    value 'TRANSPORTATION_SERVICES', '(4) Transportation services', value: 4
    value 'INCOME_SUPPORT_SERVICES', '(5) Income support services', value: 5
    value 'FIDUCIARY_AND_REPRESENTATIVE_PAYEE_SERVICES', '(6) Fiduciary and representative payee services', value: 6
    value 'LEGAL_SERVICES_CHILD_SUPPORT', '(7) Legal services - child support', value: 7
    value 'LEGAL_SERVICES_EVICTION_PREVENTION', '(8) Legal services - eviction prevention', value: 8
    value 'LEGAL_SERVICES_OUTSTANDING_FINES_AND_PENALTIES', '(9) Legal services - outstanding fines and penalties', value: 9
    value 'LEGAL_SERVICES_RESTORE_ACQUIRE_DRIVER_S_LICENSE', "(10) Legal services - restore / acquire driver's license", value: 10
    value 'LEGAL_SERVICES_OTHER', '(11) Legal services - other', value: 11
    value 'CHILD_CARE', '(12) Child care', value: 12
    value 'HOUSING_COUNSELING', '(13) Housing counseling', value: 13
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SSVFSubType5 < Types::BaseEnum
    description 'HUD SSVFSubType5 (V2.C)'
    graphql_name 'SSVFSubType5'
    value 'PERSONAL_FINANCIAL_PLANNING_SERVICES', '(1) Personal financial planning services', value: 1
    value 'TRANSPORTATION_SERVICES', '(2) Transportation services', value: 2
    value 'INCOME_SUPPORT_SERVICES', '(3) Income support services', value: 3
    value 'FIDUCIARY_AND_REPRESENTATIVE_PAYEE_SERVICES', '(4) Fiduciary and representative payee services', value: 4
    value 'LEGAL_SERVICES_CHILD_SUPPORT', '(5) Legal services - child support', value: 5
    value 'LEGAL_SERVICES_EVICTION_PREVENTION', '(6) Legal services - eviction prevention', value: 6
    value 'LEGAL_SERVICES_OUTSTANDING_FINES_AND_PENALTIES', '(7) Legal services - outstanding fines and penalties', value: 7
    value 'LEGAL_SERVICES_RESTORE_ACQUIRE_DRIVER_S_LICENSE', "(8) Legal services - restore / acquire driver's license", value: 8
    value 'LEGAL_SERVICES_OTHER', '(9) Legal services - other', value: 9
    value 'CHILD_CARE', '(10) Child care', value: 10
    value 'HOUSING_COUNSELING', '(11) Housing counseling', value: 11
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PercentAMI < Types::BaseEnum
    description 'HUD PercentAMI (V4.1)'
    graphql_name 'PercentAMI'
    value 'NUM_30_OR_LESS', '(1) 30% or less', value: 1
    value 'NUM_31_TO_50', '(2) 31% to 50%', value: 2
    value 'NUM_51_TO_80', '(3) 51% to 80%', value: 3
    value 'NUM_81_OR_GREATER', '(4) 81% or greater', value: 4
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class VamcStationNumber < Types::BaseEnum
    description 'HUD VamcStationNumber (V6.1)'
    graphql_name 'VamcStationNumber'
    value 'NUM_402_TOGUS_ME', '(402) (402) Togus, ME', value: '402'
    value 'NUM_405_WHITE_RIVER_JUNCTION_VT', '(405) (405) White River Junction, VT', value: '405'
    value 'NUM_436_MONTANA_HCS', '(436) (436) Montana HCS', value: '436'
    value 'NUM_437_FARGO_ND', '(437) (437) Fargo, ND', value: '437'
    value 'NUM_438_SIOUX_FALLS_SD', '(438) (438) Sioux Falls, SD', value: '438'
    value 'NUM_442_CHEYENNE_WY', '(442) (442) Cheyenne, WY', value: '442'
    value 'NUM_459_HONOLULU_HI', '(459) (459) Honolulu, HI', value: '459'
    value 'NUM_460_WILMINGTON_DE', '(460) (460) Wilmington, DE', value: '460'
    value 'NUM_463_ANCHORAGE_AK', '(463) (463) Anchorage, AK', value: '463'
    value 'NUM_501_NEW_MEXICO_HCS', '(501) (501) New Mexico HCS', value: '501'
    value 'NUM_502_ALEXANDRIA_LA', '(502) (502) Alexandria, LA', value: '502'
    value 'NUM_503_ALTOONA_PA', '(503) (503) Altoona, PA', value: '503'
    value 'NUM_504_AMARILLO_TX', '(504) (504) Amarillo, TX', value: '504'
    value 'NUM_506_ANN_ARBOR_MI', '(506) (506) Ann Arbor, MI', value: '506'
    value 'NUM_508_ATLANTA_GA', '(508) (508) Atlanta, GA', value: '508'
    value 'NUM_509_AUGUSTA_GA', '(509) (509) Augusta, GA', value: '509'
    value 'NUM_512_BALTIMORE_HCS_MD', '(512) (512) Baltimore HCS, MD', value: '512'
    value 'NUM_515_BATTLE_CREEK_MI', '(515) (515) Battle Creek, MI', value: '515'
    value 'NUM_516_BAY_PINES_FL', '(516) (516) Bay Pines, FL', value: '516'
    value 'NUM_517_BECKLEY_WV', '(517) (517) Beckley, WV', value: '517'
    value 'NUM_518_BEDFORD_MA', '(518) (518) Bedford, MA', value: '518'
    value 'NUM_519_BIG_SPRING_TX', '(519) (519) Big Spring, TX', value: '519'
    value 'NUM_520_GULF_COAST_HCS_MS', '(520) (520) Gulf Coast HCS, MS', value: '520'
    value 'NUM_521_BIRMINGHAM_AL', '(521) (521) Birmingham, AL', value: '521'
    value 'NUM_523_VA_BOSTON_HCS_MA', '(523) (523) VA Boston HCS, MA', value: '523'
    value 'NUM_526_BRONX_NY', '(526) (526) Bronx, NY', value: '526'
    value 'NUM_528_WESTERN_NEW_YORK_NY', '(528) (528) Western New York, NY', value: '528'
    value 'NUM_529_BUTLER_PA', '(529) (529) Butler, PA', value: '529'
    value 'NUM_531_BOISE_ID', '(531) (531) Boise, ID', value: '531'
    value 'NUM_534_CHARLESTON_SC', '(534) (534) Charleston, SC', value: '534'
    value 'NUM_537_JESSE_BROWN_VAMC_CHICAGO_IL', '(537) (537) Jesse Brown VAMC (Chicago), IL', value: '537'
    value 'NUM_538_CHILLICOTHE_OH', '(538) (538) Chillicothe, OH', value: '538'
    value 'NUM_539_CINCINNATI_OH', '(539) (539) Cincinnati, OH', value: '539'
    value 'NUM_540_CLARKSBURG_WV', '(540) (540) Clarksburg, WV', value: '540'
    value 'NUM_541_CLEVELAND_OH', '(541) (541) Cleveland, OH', value: '541'
    value 'NUM_542_COATESVILLE_PA', '(542) (542) Coatesville, PA', value: '542'
    value 'NUM_544_COLUMBIA_SC', '(544) (544) Columbia, SC', value: '544'
    value 'NUM_546_MIAMI_FL', '(546) (546) Miami, FL', value: '546'
    value 'NUM_548_WEST_PALM_BEACH_FL', '(548) (548) West Palm Beach, FL', value: '548'
    value 'NUM_549_DALLAS_TX', '(549) (549) Dallas, TX', value: '549'
    value 'NUM_550_DANVILLE_IL', '(550) (550) Danville, IL', value: '550'
    value 'NUM_552_DAYTON_OH', '(552) (552) Dayton, OH', value: '552'
    value 'NUM_553_DETROIT_MI', '(553) (553) Detroit, MI', value: '553'
    value 'NUM_554_DENVER_CO', '(554) (554) Denver, CO', value: '554'
    value 'NUM_556_CAPTAIN_JAMES_A_LOVELL_FHCC', '(556) (556) Captain James A Lovell FHCC', value: '556'
    value 'NUM_557_DUBLIN_GA', '(557) (557) Dublin, GA', value: '557'
    value 'NUM_558_DURHAM_NC', '(558) (558) Durham, NC', value: '558'
    value 'NUM_561_NEW_JERSEY_HCS_NJ', '(561) (561) New Jersey HCS, NJ', value: '561'
    value 'NUM_562_ERIE_PA', '(562) (562) Erie, PA', value: '562'
    value 'NUM_564_FAYETTEVILLE_AR', '(564) (564) Fayetteville, AR', value: '564'
    value 'NUM_565_FAYETTEVILLE_NC', '(565) (565) Fayetteville, NC', value: '565'
    value 'NUM_568_BLACK_HILLS_HCS_SD', '(568) (568) Black Hills HCS, SD', value: '568'
    value 'NUM_570_FRESNO_CA', '(570) (570) Fresno, CA', value: '570'
    value 'NUM_573_GAINESVILLE_FL', '(573) (573) Gainesville, FL', value: '573'
    value 'NUM_575_GRAND_JUNCTION_CO', '(575) (575) Grand Junction, CO', value: '575'
    value 'NUM_578_HINES_IL', '(578) (578) Hines, IL', value: '578'
    value 'NUM_580_HOUSTON_TX', '(580) (580) Houston, TX', value: '580'
    value 'NUM_581_HUNTINGTON_WV', '(581) (581) Huntington, WV', value: '581'
    value 'NUM_583_INDIANAPOLIS_IN', '(583) (583) Indianapolis, IN', value: '583'
    value 'NUM_585_IRON_MOUNTAIN_MI', '(585) (585) Iron Mountain, MI', value: '585'
    value 'NUM_586_JACKSON_MS', '(586) (586) Jackson, MS', value: '586'
    value 'NUM_589_KANSAS_CITY_MO', '(589) (589) Kansas City, MO', value: '589'
    value 'NUM_590_HAMPTON_VA', '(590) (590) Hampton, VA', value: '590'
    value 'NUM_593_LAS_VEGAS_NV', '(593) (593) Las Vegas, NV', value: '593'
    value 'NUM_595_LEBANON_PA', '(595) (595) Lebanon, PA', value: '595'
    value 'NUM_596_LEXINGTON_KY', '(596) (596) Lexington, KY', value: '596'
    value 'NUM_598_LITTLE_ROCK_AR', '(598) (598) Little Rock, AR', value: '598'
    value 'NUM_600_LONG_BEACH_CA', '(600) (600) Long Beach, CA', value: '600'
    value 'NUM_603_LOUISVILLE_KY', '(603) (603) Louisville, KY', value: '603'
    value 'NUM_605_LOMA_LINDA_CA', '(605) (605) Loma Linda, CA', value: '605'
    value 'NUM_607_MADISON_WI', '(607) (607) Madison, WI', value: '607'
    value 'NUM_608_MANCHESTER_NH', '(608) (608) Manchester, NH', value: '608'
    value 'NUM_610_NORTHERN_INDIANA_HCS_IN', '(610) (610) Northern Indiana HCS, IN', value: '610'
    value 'NUM_612_N_CALIFORNIA_CA', '(612) (612) N. California, CA', value: '612'
    value 'NUM_613_MARTINSBURG_WV', '(613) (613) Martinsburg, WV', value: '613'
    value 'NUM_614_MEMPHIS_TN', '(614) (614) Memphis, TN', value: '614'
    value 'NUM_618_MINNEAPOLIS_MN', '(618) (618) Minneapolis, MN', value: '618'
    value 'NUM_619_CENTRAL_ALABAMA_VETERANS_HCS_AL', '(619) (619) Central Alabama Veterans HCS, AL', value: '619'
    value 'NUM_620_VA_HUDSON_VALLEY_HCS_NY', '(620) (620) VA Hudson Valley HCS, NY', value: '620'
    value 'NUM_621_MOUNTAIN_HOME_TN', '(621) (621) Mountain Home, TN', value: '621'
    value 'NUM_623_MUSKOGEE_OK', '(623) (623) Muskogee, OK', value: '623'
    value 'NUM_626_MIDDLE_TENNESSEE_HCS_TN', '(626) (626) Middle Tennessee HCS, TN', value: '626'
    value 'NUM_629_NEW_ORLEANS_LA', '(629) (629) New Orleans, LA', value: '629'
    value 'NUM_630_NEW_YORK_HARBOR_HCS_NY', '(630) (630) New York Harbor HCS, NY', value: '630'
    value 'NUM_631_VA_CENTRAL_WESTERN_MASSACHUSETTS_HCS', '(631) (631) VA Central Western Massachusetts HCS', value: '631'
    value 'NUM_632_NORTHPORT_NY', '(632) (632) Northport, NY', value: '632'
    value 'NUM_635_OKLAHOMA_CITY_OK', '(635) (635) Oklahoma City, OK', value: '635'
    value 'NUM_636_NEBRASKA_W_IOWA_NE', '(636) (636) Nebraska-W Iowa, NE', value: '636'
    value 'NUM_637_ASHEVILLE_NC', '(637) (637) Asheville, NC', value: '637'
    value 'NUM_640_PALO_ALTO_CA', '(640) (640) Palo Alto, CA', value: '640'
    value 'NUM_642_PHILADELPHIA_PA', '(642) (642) Philadelphia, PA', value: '642'
    value 'NUM_644_PHOENIX_AZ', '(644) (644) Phoenix, AZ', value: '644'
    value 'NUM_646_PITTSBURGH_PA', '(646) (646) Pittsburgh, PA', value: '646'
    value 'NUM_648_PORTLAND_OR', '(648) (648) Portland, OR', value: '648'
    value 'NUM_649_NORTHERN_ARIZONA_HCS', '(649) (649) Northern Arizona HCS', value: '649'
    value 'NUM_650_PROVIDENCE_RI', '(650) (650) Providence, RI', value: '650'
    value 'NUM_652_RICHMOND_VA', '(652) (652) Richmond, VA', value: '652'
    value 'NUM_653_ROSEBURG_OR', '(653) (653) Roseburg, OR', value: '653'
    value 'NUM_654_RENO_NV', '(654) (654) Reno, NV', value: '654'
    value 'NUM_655_SAGINAW_MI', '(655) (655) Saginaw, MI', value: '655'
    value 'NUM_656_ST_CLOUD_MN', '(656) (656) St. Cloud, MN', value: '656'
    value 'NUM_657_ST_LOUIS_MO', '(657) (657) St. Louis, MO', value: '657'
    value 'NUM_658_SALEM_VA', '(658) (658) Salem, VA', value: '658'
    value 'NUM_659_SALISBURY_NC', '(659) (659) Salisbury, NC', value: '659'
    value 'NUM_660_SALT_LAKE_CITY_UT', '(660) (660) Salt Lake City, UT', value: '660'
    value 'NUM_662_SAN_FRANCISCO_CA', '(662) (662) San Francisco, CA', value: '662'
    value 'NUM_663_VA_PUGET_SOUND_WA', '(663) (663) VA Puget Sound, WA', value: '663'
    value 'NUM_664_SAN_DIEGO_CA', '(664) (664) San Diego, CA', value: '664'
    value 'NUM_666_SHERIDAN_WY', '(666) (666) Sheridan, WY', value: '666'
    value 'NUM_667_SHREVEPORT_LA', '(667) (667) Shreveport, LA', value: '667'
    value 'NUM_668_SPOKANE_WA', '(668) (668) Spokane, WA', value: '668'
    value 'NUM_671_SAN_ANTONIO_TX', '(671) (671) San Antonio, TX', value: '671'
    value 'NUM_672_SAN_JUAN_PR', '(672) (672) San Juan, PR', value: '672'
    value 'NUM_673_TAMPA_FL', '(673) (673) Tampa, FL', value: '673'
    value 'NUM_674_TEMPLE_TX', '(674) (674) Temple, TX', value: '674'
    value 'NUM_675_ORLANDO_FL', '(675) (675) Orlando, FL', value: '675'
    value 'NUM_676_TOMAH_WI', '(676) (676) Tomah, WI', value: '676'
    value 'NUM_678_SOUTHERN_ARIZONA_HCS', '(678) (678) Southern Arizona HCS', value: '678'
    value 'NUM_679_TUSCALOOSA_AL', '(679) (679) Tuscaloosa, AL', value: '679'
    value 'NUM_687_WALLA_WALLA_WA', '(687) (687) Walla Walla, WA', value: '687'
    value 'NUM_688_WASHINGTON_DC', '(688) (688) Washington, DC', value: '688'
    value 'NUM_689_VA_CONNECTICUT_HCS_CT', '(689) (689) VA Connecticut HCS, CT', value: '689'
    value 'NUM_691_GREATER_LOS_ANGELES_HCS', '(691) (691) Greater Los Angeles HCS', value: '691'
    value 'NUM_692_WHITE_CITY_OR', '(692) (692) White City, OR', value: '692'
    value 'NUM_693_WILKES_BARRE_PA', '(693) (693) Wilkes-Barre, PA', value: '693'
    value 'NUM_695_MILWAUKEE_WI', '(695) (695) Milwaukee, WI', value: '695'
    value 'NUM_740_VA_TEXAS_VALLEY_COASTAL_BEND_HCS', '(740) (740) VA Texas Valley Coastal Bend HCS', value: '740'
    value 'NUM_756_EL_PASO_TX', '(756) (756) El Paso, TX', value: '756'
    value 'NUM_757_COLUMBUS_OH', '(757) (757) Columbus, OH', value: '757'
    value 'NUM_459_GE_GUAM', '(459GE) (459GE) Guam', value: '459GE'
    value 'NUM_528_A5_CANANDAIGUA_NY', '(528A5) (528A5) Canandaigua, NY', value: '528A5'
    value 'NUM_528_A6_BATH_NY', '(528A6) (528A6) Bath, NY', value: '528A6'
    value 'NUM_528_A7_SYRACUSE_NY', '(528A7) (528A7) Syracuse, NY', value: '528A7'
    value 'NUM_528_A8_ALBANY_NY', '(528A8) (528A8) Albany, NY', value: '528A8'
    value 'NUM_589_A4_COLUMBIA_MO', '(589A4) (589A4) Columbia, MO', value: '589A4'
    value 'NUM_589_A5_KANSAS_CITY_MO', '(589A5) (589A5) Kansas City, MO', value: '589A5'
    value 'NUM_589_A6_EASTERN_KS_HCS_KS', '(589A6) (589A6) Eastern KS HCS, KS', value: '589A6'
    value 'NUM_589_A7_WICHITA_KS', '(589A7) (589A7) Wichita, KS', value: '589A7'
    value 'NUM_636_A6_CENTRAL_IOWA_IA', '(636A6) (636A6) Central Iowa, IA', value: '636A6'
    value 'NUM_636_A8_IOWA_CITY_IA', '(636A8) (636A8) Iowa City, IA', value: '636A8'
    value 'NUM_657_A4_POPLAR_BLUFF_MO', '(657A4) (657A4) Poplar Bluff, MO', value: '657A4'
    value 'NUM_657_A5_MARION_IL', '(657A5) (657A5) Marion, IL', value: '657A5'
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: '99'
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NoPointsYes < Types::BaseEnum
    description 'HUD NoPointsYes (V7.1)'
    graphql_name 'NoPointsYes'
    value 'NO_0_POINTS', '(0) No (0 points)', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class TimeToHousingLoss < Types::BaseEnum
    description 'HUD TimeToHousingLoss (V7.A)'
    graphql_name 'TimeToHousingLoss'
    value 'NUM_1_6_DAYS', '(0) 1-6 days', value: 0
    value 'NUM_7_13_DAYS', '(1) 7-13 days', value: 1
    value 'NUM_14_21_DAYS', '(2) 14-21 days', value: 2
    value 'MORE_THAN_21_DAYS', '(3) More than 21 days', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class AnnualPercentAMI < Types::BaseEnum
    description 'HUD AnnualPercentAMI (V7.B)'
    graphql_name 'AnnualPercentAMI'
    value 'NUM_0', '(0) $0 (i.e., not employed, not receiving cash benefits, no other current income)', value: 0
    value 'NUM_1_14_OF_AREA_MEDIAN_INCOME_AMI_FOR_HOUSEHOLD_SIZE', '(1) 1-14% of Area Median Income (AMI) for household size', value: 1
    value 'NUM_15_30_OF_AMI_FOR_HOUSEHOLD_SIZE', '(2) 15-30% of AMI for household size', value: 2
    value 'MORE_THAN_30_OF_AMI_FOR_HOUSEHOLD_SIZE', '(3) More than 30% of AMI for household size', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class LiteralHomelessHistory < Types::BaseEnum
    description 'HUD LiteralHomelessHistory (V7.C)'
    graphql_name 'LiteralHomelessHistory'
    value 'MOST_RECENT_EPISODE_OCCURRED_IN_THE_LAST_YEAR', '(0) Most recent episode occurred in the last year', value: 0
    value 'MOST_RECENT_EPISODE_OCCURRED_MORE_THAN_ONE_YEAR_AGO', '(1) Most recent episode occurred more than one year ago', value: 1
    value 'NONE', '(2) None', value: 2
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class EvictionHistory < Types::BaseEnum
    description 'HUD EvictionHistory (V7.G)'
    graphql_name 'EvictionHistory'
    value 'NO_PRIOR_RENTAL_EVICTIONS', '(0) No prior rental evictions', value: 0
    value 'NUM_1_PRIOR_RENTAL_EVICTION', '(1) 1 prior rental eviction', value: 1
    value 'NUM_2_OR_MORE_PRIOR_RENTAL_EVICTIONS', '(2) 2 or more prior rental evictions', value: 2
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class IncarceratedAdult < Types::BaseEnum
    description 'HUD IncarceratedAdult (V7.I)'
    graphql_name 'IncarceratedAdult'
    value 'NOT_INCARCERATED', '(0) Not incarcerated', value: 0
    value 'INCARCERATED_ONCE', '(1) Incarcerated once', value: 1
    value 'INCARCERATED_TWO_OR_MORE_TIMES', '(2) Incarcerated two or more times', value: 2
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class DependentUnder6 < Types::BaseEnum
    description 'HUD DependentUnder6 (V7.O)'
    graphql_name 'DependentUnder6'
    value 'NO', '(0) No', value: 0
    value 'YOUNGEST_CHILD_IS_UNDER_1_YEAR_OLD', '(1) Youngest child is under 1 year old', value: 1
    value 'YOUNGEST_CHILD_IS_1_TO_6_YEARS_OLD_AND_OR_ONE_OR_MORE_CHILDREN_ANY_AGE_REQUIRE_SIGNIFICANT_CARE', '(2) Youngest child is 1 to 6 years old and/or one or more children (any age) require significant care', value: 2
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class VoucherTracking < Types::BaseEnum
    description 'HUD VoucherTracking (V8.1)'
    graphql_name 'VoucherTracking'
    value 'REFERRAL_PACKAGE_FORWARDED_TO_PHA', '(1) Referral package forwarded to PHA', value: 1
    value 'VOUCHER_DENIED_BY_PHA', '(2) Voucher denied by PHA', value: 2
    value 'VOUCHER_ISSUED_BY_PHA', '(3) Voucher issued by PHA', value: 3
    value 'VOUCHER_REVOKED_OR_EXPIRED', '(4) Voucher revoked or expired', value: 4
    value 'VOUCHER_IN_USE_VETERAN_MOVED_INTO_HOUSING', '(5) Voucher in use - veteran moved into housing', value: 5
    value 'VOUCHER_WAS_PORTED_LOCALLY', '(6) Voucher was ported locally', value: 6
    value 'VOUCHER_WAS_ADMINISTRATIVELY_ABSORBED_BY_NEW_PHA', '(7) Voucher was administratively absorbed by new PHA', value: 7
    value 'VOUCHER_WAS_CONVERTED_TO_HOUSING_CHOICE_VOUCHER', '(8) Voucher was converted to Housing Choice Voucher', value: 8
    value 'VETERAN_EXITED_VOUCHER_WAS_RETURNED', '(9) Veteran exited - voucher was returned', value: 9
    value 'VETERAN_EXITED_FAMILY_MAINTAINED_THE_VOUCHER', '(10) Veteran exited - family maintained the voucher', value: 10
    value 'VETERAN_EXITED_PRIOR_TO_EVER_RECEIVING_A_VOUCHER', '(11) Veteran exited - prior to ever receiving a voucher', value: 11
    value 'OTHER', '(12) Other', value: 12
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class CmExitReason < Types::BaseEnum
    description 'HUD CmExitReason (V9.1)'
    graphql_name 'CmExitReason'
    value 'ACCOMPLISHED_GOALS_AND_OR_OBTAINED_SERVICES_AND_NO_LONGER_NEEDS_CM', '(1) Accomplished goals and/or obtained services and no longer needs CM', value: 1
    value 'TRANSFERRED_TO_ANOTHER_HUD_VASH_PROGRAM_SITE', '(2) Transferred to another HUD/VASH program site', value: 2
    value 'FOUND_CHOSE_OTHER_HOUSING', '(3) Found/chose other housing', value: 3
    value 'DID_NOT_COMPLY_WITH_HUD_VASH_CM', '(4) Did not comply with HUD/VASH CM', value: 4
    value 'EVICTION_AND_OR_OTHER_HOUSING_RELATED_ISSUES', '(5) Eviction and/or other housing related issues', value: 5
    value 'UNHAPPY_WITH_HUD_VASH_HOUSING', '(6) Unhappy with HUD/VASH housing', value: 6
    value 'NO_LONGER_FINANCIALLY_ELIGIBLE_FOR_HUD_VASH_VOUCHER', '(7) No longer financially eligible for HUD/VASH voucher', value: 7
    value 'NO_LONGER_INTERESTED_IN_PARTICIPATING_IN_THIS_PROGRAM', '(8) No longer interested in participating in this program', value: 8
    value 'VETERAN_CANNOT_BE_LOCATED', '(9) Veteran cannot be located', value: 9
    value 'VETERAN_TOO_ILL_TO_PARTICIPATE_AT_THIS_TIME', '(10) Veteran too ill to participate at this time', value: 10
    value 'VETERAN_IS_INCARCERATED', '(11) Veteran is incarcerated', value: 11
    value 'VETERAN_IS_DECEASED', '(12) Veteran is deceased', value: 12
    value 'OTHER', '(13) Other', value: 13
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HOPWAServices < Types::BaseEnum
    description 'HUD HOPWAServices (W1.2)'
    graphql_name 'HOPWAServices'
    value 'ADULT_DAY_CARE_AND_PERSONAL_ASSISTANCE', '(1) Adult day care and personal assistance', value: 1
    value 'CASE_MANAGEMENT', '(2) Case management', value: 2
    value 'CHILD_CARE', '(3) Child care', value: 3
    value 'CRIMINAL_JUSTICE_LEGAL_SERVICES', '(4) Criminal justice/legal services', value: 4
    value 'EDUCATION', '(5) Education', value: 5
    value 'EMPLOYMENT_AND_TRAINING_SERVICES', '(6) Employment and training services', value: 6
    value 'FOOD_MEALS_NUTRITIONAL_SERVICES', '(7) Food/meals/nutritional services', value: 7
    value 'HEALTH_MEDICAL_CARE', '(8) Health/medical care', value: 8
    value 'LIFE_SKILLS_TRAINING', '(9) Life skills training', value: 9
    value 'MENTAL_HEALTH_CARE_COUNSELING', '(10) Mental health care/counseling', value: 10
    value 'OUTREACH_AND_OR_ENGAGEMENT', '(11) Outreach and/or engagement', value: 11
    value 'SUBSTANCE_USE_SERVICES_TREATMENT', '(12) Substance use services/treatment', value: 12
    value 'TRANSPORTATION', '(13) Transportation', value: 13
    value 'OTHER_HOPWA_FUNDED_SERVICE', '(14) Other HOPWA funded service', value: 14
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class NoAssistanceReason < Types::BaseEnum
    description 'HUD NoAssistanceReason (W3)'
    graphql_name 'NoAssistanceReason'
    value 'APPLIED_DECISION_PENDING', '(1) Applied; decision pending', value: 1
    value 'APPLIED_CLIENT_NOT_ELIGIBLE', '(2) Applied; client not eligible', value: 2
    value 'CLIENT_DID_NOT_APPLY', '(3) Client did not apply', value: 3
    value 'INSURANCE_TYPE_NOT_APPLICABLE_FOR_THIS_CLIENT', '(4) Insurance type not applicable for this client', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class ViralLoadAvailable < Types::BaseEnum
    description 'HUD ViralLoadAvailable (W4.3)'
    graphql_name 'ViralLoadAvailable'
    value 'NOT_AVAILABLE', '(0) Not available', value: 0
    value 'AVAILABLE', '(1) Available', value: 1
    value 'UNDETECTABLE', '(2) Undetectable', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class TCellSourceViralLoadSource < Types::BaseEnum
    description 'HUD TCellSourceViralLoadSource (W4.B)'
    graphql_name 'TCellSourceViralLoadSource'
    value 'MEDICAL_REPORT', '(1) Medical Report', value: 1
    value 'CLIENT_REPORT', '(2) Client Report', value: 2
    value 'OTHER', '(3) Other', value: 3
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class HousingAssessmentAtExit < Types::BaseEnum
    description 'HUD HousingAssessmentAtExit (W5.1)'
    graphql_name 'HousingAssessmentAtExit'
    value 'ABLE_TO_MAINTAIN_THE_HOUSING_THEY_HAD_AT_PROJECT_ENTRY', '(1) Able to maintain the housing they had at project entry', value: 1
    value 'MOVED_TO_NEW_HOUSING_UNIT', '(2) Moved to new housing unit', value: 2
    value 'MOVED_IN_WITH_FAMILY_FRIENDS_ON_A_TEMPORARY_BASIS', '(3) Moved in with family/friends on a temporary basis', value: 3
    value 'MOVED_IN_WITH_FAMILY_FRIENDS_ON_A_PERMANENT_BASIS', '(4) Moved in with family/friends on a permanent basis', value: 4
    value 'MOVED_TO_A_TRANSITIONAL_OR_TEMPORARY_HOUSING_FACILITY_OR_PROGRAM', '(5) Moved to a transitional or temporary housing facility or program', value: 5
    value 'CLIENT_BECAME_HOMELESS_MOVING_TO_A_SHELTER_OR_OTHER_PLACE_UNFIT_FOR_HUMAN_HABITATION', '(6) Client became homeless - moving to a shelter or other place unfit for human habitation', value: 6
    value 'JAIL_PRISON', '(7) Jail/prison', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DECEASED', '(10) Deceased', value: 10
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SubsidyInformation < Types::BaseEnum
    description 'HUD SubsidyInformation (W5.AB)'
    graphql_name 'SubsidyInformation'
    value 'WITHOUT_A_SUBSIDY', '(1) Without a subsidy', value: 1
    value 'WITH_THE_SUBSIDY_THEY_HAD_AT_PROJECT_ENTRY', '(2) With the subsidy they had at project entry', value: 2
    value 'WITH_AN_ON_GOING_SUBSIDY_ACQUIRED_SINCE_PROJECT_ENTRY', '(3) With an on-going subsidy acquired since project entry', value: 3
    value 'ONLY_WITH_FINANCIAL_ASSISTANCE_OTHER_THAN_A_SUBSIDY', '(4) Only with financial assistance other than a subsidy', value: 4
    value 'WITH_ON_GOING_SUBSIDY', '(11) With on-going subsidy', value: 11
    value 'WITHOUT_AN_ON_GOING_SUBSIDY', '(12) Without an on-going subsidy', value: 12
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SubsidyInformationA < Types::BaseEnum
    description 'HUD SubsidyInformationA (W5.A)'
    graphql_name 'SubsidyInformationA'
    value 'WITHOUT_A_SUBSIDY', '(1) Without a subsidy', value: 1
    value 'WITH_THE_SUBSIDY_THEY_HAD_AT_PROJECT_ENTRY', '(2) With the subsidy they had at project entry', value: 2
    value 'WITH_AN_ON_GOING_SUBSIDY_ACQUIRED_SINCE_PROJECT_ENTRY', '(3) With an on-going subsidy acquired since project entry', value: 3
    value 'ONLY_WITH_FINANCIAL_ASSISTANCE_OTHER_THAN_A_SUBSIDY', '(4) Only with financial assistance other than a subsidy', value: 4
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class SubsidyInformationB < Types::BaseEnum
    description 'HUD SubsidyInformationB (W5.B)'
    graphql_name 'SubsidyInformationB'
    value 'WITH_ON_GOING_SUBSIDY', '(11) With on-going subsidy', value: 11
    value 'WITHOUT_AN_ON_GOING_SUBSIDY', '(12) Without an on-going subsidy', value: 12
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class AdHocYesNo < Types::BaseEnum
    description 'HUD AdHocYesNo (ad_hoc_yes_no)'
    graphql_name 'AdHocYesNo'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'DON_T_KNOW', "(8) Don't Know", value: 8
    value 'PREFERS_NOT_TO_ANSWER', '(9) Prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end

  class PreferredLanguage < Types::BaseEnum
    description 'HUD PreferredLanguage (C4.A)'
    graphql_name 'PreferredLanguage'
    value 'ACHOLI', '(100) Acholi', value: 100
    value 'AFAR', '(101) Afar', value: 101
    value 'AFRIKAANS', '(102) Afrikaans', value: 102
    value 'AHTNA', '(103) Ahtna', value: 103
    value 'AKAN', '(104) Akan', value: 104
    value 'AKATEKO', '(105) Akateko', value: 105
    value 'AKUZIPIGESTUN_ST_LAWRENCE_ISLAND_YUPIK', '(106) Akuzipigestun / St. Lawrence Island Yupik (aka Siberian Yupik)', value: 106
    value 'ALBANIAN', '(107) Albanian', value: 107
    value 'ALGONQUIAN', '(108) Algonquian', value: 108
    value 'ALUTIIQ', '(109) Alutiiq', value: 109
    value 'AMERICAN_SIGN_LANGUAGE', '(110) American Sign Language', value: 110
    value 'AMHARIC', '(111) Amharic', value: 111
    value 'ANUAK', '(112) Anuak', value: 112
    value 'APACHE', '(113) Apache', value: 113
    value 'ARABIC', '(114) Arabic', value: 114
    value 'ARMENIAN', '(115) Armenian', value: 115
    value 'ASSYRIAN', '(116) Assyrian', value: 116
    value 'ATNAKENAEGE_AHTNA', '(117) Atnakenaege’ / Ahtna', value: 117
    value 'AYMARA', '(118) Aymara', value: 118
    value 'AZERBAIJANI', '(119) Azerbaijani', value: 119
    value 'BAHASA', '(120) Bahasa', value: 120
    value 'BAHDINI', '(121) Bahdini', value: 121
    value 'BAJUNI', '(122) Bajuni', value: 122
    value 'BAMBARA', '(123) Bambara', value: 123
    value 'BANTU', '(124) Bantu', value: 124
    value 'BARESE', '(125) Barese', value: 125
    value 'BASQUE', '(126) Basque', value: 126
    value 'BASSA', '(127) Bassa', value: 127
    value 'BELORUSSIAN', '(128) Belorussian', value: 128
    value 'BEMBA', '(129) Bemba', value: 129
    value 'BENAADIR', '(130) Benaadir', value: 130
    value 'BENGALI', '(131) Bengali', value: 131
    value 'BERBER', '(132) Berber', value: 132
    value 'BLACK_AMERICAN_SIGN_LANGUAGE', '(133) Black American Sign Language', value: 133
    value 'BOSNIAN', '(134) Bosnian', value: 134
    value 'BRAVANESE', '(135) Bravanese', value: 135
    value 'BULGARIAN', '(136) Bulgarian', value: 136
    value 'BURMESE', '(137) Burmese', value: 137
    value 'CAMBODIAN', '(138) Cambodian', value: 138
    value 'CANTONESE', '(139) Cantonese', value: 139
    value 'CAPE_VERDEAN_CREOLE', '(140) Cape Verdean Creole', value: 140
    value 'CATALAN', '(141) Catalan', value: 141
    value 'CEBUANO', '(142) Cebuano', value: 142
    value 'CENTRAL_ALASKAN_YUP_IK_YUGTUN', '(143) Central Alaskan Yup’ik / Yugtun', value: 143
    value 'CHALDEAN', '(144) Chaldean', value: 144
    value 'CHAMORRO', '(145) Chamorro', value: 145
    value 'CHAOCHOW', '(146) Chaochow', value: 146
    value 'CHEROKEE', '(147) Cherokee', value: 147
    value 'CHINESE', '(148) Chinese', value: 148
    value 'CHIPEWYAN', '(149) Chipewyan', value: 149
    value 'CHOCTAW', '(150) Choctaw', value: 150
    value 'CHUUKESE', '(151) Chuukese', value: 151
    value 'CREE', '(152) Cree', value: 152
    value 'CROATIAN', '(153) Croatian', value: 153
    value 'CZECH', '(154) Czech', value: 154
    value 'DAKOTA', '(155) Dakota', value: 155
    value 'DANISH', '(156) Danish', value: 156
    value 'DARI', '(157) Dari', value: 157
    value 'DEG_XINAG', '(158) Deg Xinag', value: 158
    value 'DENA_INAQ_DENA_INA', "(159) Dena'inaq' / Dena'ina", value: 159
    value 'DENAAKK_E_KOYUKON', "(160) Denaakk'e / Koyukon", value: 160
    value 'DEWOIN', '(161) Dewoin', value: 161
    value 'DINAK_I_UPPER_KUSKOKWIM', "(162) Dinak'i / Upper Kuskokwim", value: 162
    value 'DINJII_ZHUH_K_YAA_GWICH_IN', "(163) Dinjii Zhuh K'yaa / Gwich'in", value: 163
    value 'DINKA', '(164) Dinka', value: 164
    value 'DOOGH_QINAQ_HOLIKACHUK', '(165) Doogh Qinaq / Holikachuk', value: 165
    value 'DUALA', '(166) Duala', value: 166
    value 'DUTCH', '(167) Dutch', value: 167
    value 'DZONGKHA', '(168) Dzongkha', value: 168
    value 'EDO', '(169) Edo', value: 169
    value 'EKEGUSLI', '(170) Ekegusli', value: 170
    value 'ENGLISH', '(171) English', value: 171
    value 'ESTONIAN', '(172) Estonian', value: 172
    value 'EWE', '(173) Ewe', value: 173
    value 'EYAK', '(174) Eyak', value: 174
    value 'FARSI', '(175) Farsi', value: 175
    value 'FIJIAN', '(176) Fijian', value: 176
    value 'FILIPINO', '(177) Filipino', value: 177
    value 'FINNISH', '(178) Finnish', value: 178
    value 'FLEMISH', '(179) Flemish', value: 179
    value 'FRENCH', '(180) French', value: 180
    value 'FRENCH_CAJUN', '(181) French Cajun', value: 181
    value 'FRENCH_CANADIAN', '(182) French Canadian', value: 182
    value 'FRENCH_CREOLE', '(183) French Creole', value: 183
    value 'FRENCH_HAITIAN', '(184) French Haitian', value: 184
    value 'FUKIENESE', '(185) Fukienese', value: 185
    value 'FULANI', '(186) Fulani', value: 186
    value 'FUZHOU', '(187) Fuzhou', value: 187
    value 'GA', '(188) Ga', value: 188
    value 'GADDANG', '(189) Gaddang', value: 189
    value 'GAELIC', '(190) Gaelic', value: 190
    value 'GARRE', '(191) Garre', value: 191
    value 'GEN', '(192) Gen', value: 192
    value 'GEORGIAN', '(193) Georgian', value: 193
    value 'GERMAN', '(194) German', value: 194
    value 'GHEG', '(195) Gheg', value: 195
    value 'GOKANA', '(196) Gokana', value: 196
    value 'GREEK', '(197) Greek', value: 197
    value 'GUJARATI', '(198) Gujarati', value: 198
    value 'GULAY', '(199) Gulay', value: 199
    value 'GULLAH', '(200) Gullah', value: 200
    value 'GURANI', '(201) Gurani', value: 201
    value 'GWICH_IN', "(202) Gwich'in", value: 202
    value 'HAIDA', '(203) Haida', value: 203
    value 'HAITIAN', '(204) Haitian', value: 204
    value 'HAITIAN_CREOLE', '(205) Haitian Creole', value: 205
    value 'HAKKA', '(206) Hakka', value: 206
    value 'H_L_GOLAN_H_N', '(207) Häl golan / Hän', value: 207
    value 'HASSANIYYA', '(208) Hassaniyya', value: 208
    value 'HAUSA', '(209) Hausa', value: 209
    value 'HAWAI_I_SIGN_LANGUAGE', "(210) Hawai'i Sign Language", value: 210
    value 'HAWAIIAN', '(211) Hawaiian', value: 211
    value 'HEBREW', '(212) Hebrew', value: 212
    value 'HILIGAYNON', '(213) Hiligaynon', value: 213
    value 'HINDI', '(214) Hindi', value: 214
    value 'HINDKO', '(215) Hindko', value: 215
    value 'HMONG', '(216) Hmong', value: 216
    value 'HOKKIEN', '(217) Hokkien', value: 217
    value 'HOLIKACHUK', '(218) Holikachuk', value: 218
    value 'HOPI', '(219) Hopi', value: 219
    value 'HUANESE', '(220) Huanese', value: 220
    value 'HUNGARIAN', '(221) Hungarian', value: 221
    value 'IBANAG', '(222) Ibanag', value: 222
    value 'ICELANDIC', '(223) Icelandic', value: 223
    value 'IGBO', '(224) Igbo', value: 224
    value 'ILOCANO', '(225) Ilocano', value: 225
    value 'INDONESIAN', '(226) Indonesian', value: 226
    value 'INUKTITUT', '(227) Inuktitut', value: 227
    value 'INUPIATUN_INUPIAQ', '(228) Inupiatun / Inupiaq', value: 228
    value 'ITALIAN', '(229) Italian', value: 229
    value 'JAKARTANESE', '(230) Jakartanese', value: 230
    value 'JAMAICAN_PATOIS', '(231) Jamaican Patois', value: 231
    value 'JAPANESE', '(232) Japanese', value: 232
    value 'JARAI', '(233) Jarai', value: 233
    value 'JAVANESE', '(234) Javanese', value: 234
    value 'JINGPHO', '(235) Jingpho', value: 235
    value 'JINYU', '(236) Jinyu', value: 236
    value 'JUBA_ARABIC', '(237) Juba Arabic', value: 237
    value 'JULA', '(238) Jula', value: 238
    value 'KABA', '(239) Kaba', value: 239
    value 'KAMBA', '(240) Kamba', value: 240
    value 'KAM_MUANG', '(241) Kam Muang', value: 241
    value 'KANJOBAL', '(242) Kanjobal', value: 242
    value 'KANNADA', '(243) Kannada', value: 243
    value 'KAREN', '(244) Karen', value: 244
    value 'KASHMIRI', '(245) Kashmiri', value: 245
    value 'KAYAH', '(246) Kayah', value: 246
    value 'KAZAKH', '(247) Kazakh', value: 247
    value 'KERESAN', '(248) Keresan', value: 248
    value 'KERESAN_SIGN_LANGUAGE', '(249) Keresan Sign Language', value: 249
    value 'KHAM', '(250) Kham', value: 250
    value 'KHANA', '(251) Khana', value: 251
    value 'KHMER', '(252) Khmer', value: 252
    value 'K_ICHE', "(253) K'iche'", value: 253
    value 'KIKUYU', '(254) Kikuyu', value: 254
    value 'KIMIIRU', '(255) Kimiiru', value: 255
    value 'KINYARWANDA', '(256) Kinyarwanda', value: 256
    value 'KIOWA', '(257) Kiowa', value: 257
    value 'KOHO', '(258) Koho', value: 258
    value 'KOREAN', '(259) Korean', value: 259
    value 'KOYUKON', '(260) Koyukon', value: 260
    value 'KRAHN', '(261) Krahn', value: 261
    value 'KRIO', '(262) Krio', value: 262
    value 'KUNAMA', '(263) Kunama', value: 263
    value 'KURMANJI', '(264) Kurmanji', value: 264
    value 'KYRGYZ', '(265) Kyrgyz', value: 265
    value 'LAKOTA', '(266) Lakota', value: 266
    value 'LAOTIAN', '(267) Laotian', value: 267
    value 'LATVIAN', '(268) Latvian', value: 268
    value 'LIBERIAN_PIDGIN_ENGLISH', '(269) Liberian Pidgin English', value: 269
    value 'LINGALA', '(270) Lingala', value: 270
    value 'LING_T_TLINGIT', '(271) Lingít / Tlingit', value: 271
    value 'LITHUANIAN', '(272) Lithuanian', value: 272
    value 'LOMBARD', '(273) Lombard', value: 273
    value 'LUBA_KASAI', '(274) Luba-Kasai', value: 274
    value 'LUGANDA', '(275) Luganda', value: 275
    value 'LUO', '(276) Luo', value: 276
    value 'MAAY', '(277) Maay', value: 277
    value 'MACEDONIAN', '(278) Macedonian', value: 278
    value 'MALAY', '(279) Malay', value: 279
    value 'MALAYALAM', '(280) Malayalam', value: 280
    value 'MALTESE', '(281) Maltese', value: 281
    value 'MAM', '(282) Mam', value: 282
    value 'MANDARIN', '(283) Mandarin', value: 283
    value 'MANDINKA', '(284) Mandinka', value: 284
    value 'MANINKA', '(285) Maninka', value: 285
    value 'MANOBO', '(286) Manobo', value: 286
    value 'MARATHI', '(287) Marathi', value: 287
    value 'MARKA', '(288) Marka', value: 288
    value 'MARSHALLESE', '(289) Marshallese', value: 289
    value 'MASALIT', '(290) Masalit', value: 290
    value 'MBAY', '(291) Mbay', value: 291
    value 'MIEN', '(292) Mien', value: 292
    value 'MIRPURI', '(293) Mirpuri', value: 293
    value 'MIXTECO', '(294) Mixteco', value: 294
    value 'MIZO', '(295) Mizo', value: 295
    value 'MNONG', '(296) Mnong', value: 296
    value 'MONGOLIAN', '(297) Mongolian', value: 297
    value 'MONTENEGRIN', '(298) Montenegrin', value: 298
    value 'MOROCCAN_ARABIC', '(299) Moroccan Arabic', value: 299
    value 'MORTLOCKESE', '(300) Mortlockese', value: 300
    value 'MUSCOGEE', '(301) Muscogee', value: 301
    value 'NAPOLETANO', '(302) Napoletano', value: 302
    value 'NAVAJO', '(303) Navajo', value: 303
    value 'NAVAJO_FAMILY_SIGN', '(304) Navajo Family Sign', value: 304
    value 'NDEBELE', '(305) Ndebele', value: 305
    value 'NEAPOLITAN', '(306) Neapolitan', value: 306
    value 'NEE_AANDEG_TANACROSS', '(307) Nee’aandeg’ / Tanacross', value: 307
    value 'NEPALI', '(308) Nepali', value: 308
    value 'NGAMBAY', '(309) Ngambay', value: 309
    value 'NIGERIAN_PIDGIN', '(310) Nigerian Pidgin', value: 310
    value 'NORTHERN_SOTHO', '(311) Northern Sotho', value: 311
    value 'NORWEGIAN', '(312) Norwegian', value: 312
    value 'NUER', '(313) Nuer', value: 313
    value 'NUPE', '(314) Nupe', value: 314
    value 'NYANJA', '(315) Nyanja', value: 315
    value 'NYORO', '(316) Nyoro', value: 316
    value 'O_ODHAM', "(317) O'odham", value: 317
    value 'OJIBWE', '(318) Ojibwe', value: 318
    value 'OROMO', '(319) Oromo', value: 319
    value 'PAMPANGAN', '(320) Pampangan', value: 320
    value 'PAPIAMENTO', '(321) Papiamento', value: 321
    value 'PASHTO', '(322) Pashto', value: 322
    value 'PENNSYLVANIA_DUTCH', '(323) Pennsylvania Dutch', value: 323
    value 'PERSIAN', '(324) Persian', value: 324
    value 'PLAINS_SIGN_LANGUAGE', '(325) Plains Sign Language', value: 325
    value 'PLATEAU_SIGN_LANGUAGE', '(326) Plateau Sign Language', value: 326
    value 'PLAUTDIETSCH', '(327) Plautdietsch', value: 327
    value 'POHNPEIAN', '(328) Pohnpeian', value: 328
    value 'POLISH', '(329) Polish', value: 329
    value 'PORTUGUESE', '(330) Portuguese', value: 330
    value 'PORTUGUESE_BRAZILIAN', '(331) Portuguese Brazilian', value: 331
    value 'PORTUGUESE_CAPE_VERDEAN', '(332) Portuguese Cape Verdean', value: 332
    value 'PORTUGUESE_CREOLE', '(333) Portuguese Creole', value: 333
    value 'PUERTO_RICAN_SIGN_LANGUAGE', '(334) Puerto Rican Sign Language', value: 334
    value 'PUGLIESE', '(335) Pugliese', value: 335
    value 'PULAAR', '(336) Pulaar', value: 336
    value 'PUNJABI', '(337) Punjabi', value: 337
    value 'PUTIAN', '(338) Putian', value: 338
    value 'QUECHUA', '(339) Quechua', value: 339
    value 'QUICHUA', '(340) Quichua', value: 340
    value 'RADE', '(341) Rade', value: 341
    value 'RAKHINE', '(342) Rakhine', value: 342
    value 'ROHINGYA', '(343) Rohingya', value: 343
    value 'ROMANIAN', '(344) Romanian', value: 344
    value 'KIRUNDI', '(345) Kirundi', value: 345
    value 'RUSSIAN', '(346) Russian', value: 346
    value 'SAMOAN', '(347) Samoan', value: 347
    value 'SAMOAN_SIGN_LANGUAGE', '(348) Samoan Sign Language', value: 348
    value 'SANGO', '(349) Sango', value: 349
    value 'SERAIKI', '(350) Seraiki', value: 350
    value 'SERBIAN', '(351) Serbian', value: 351
    value 'SHANGHAINESE', '(352) Shanghainese', value: 352
    value 'SHONA', '(353) Shona', value: 353
    value 'SICHUAN_YI', '(354) Sichuan Yi', value: 354
    value 'SICILIAN', '(355) Sicilian', value: 355
    value 'SINDHI', '(356) Sindhi', value: 356
    value 'SINHALESE', '(357) Sinhalese', value: 357
    value 'SIOUX', '(358) Sioux', value: 358
    value 'SLOVAK', '(359) Slovak', value: 359
    value 'SLOVENIAN', '(360) Slovenian', value: 360
    value 'SM_ALGYAX_COAST_TSIMSHIAN', '(361) Sm’algyax / (Coast) Tsimshian', value: 361
    value 'SOGA', '(362) Soga', value: 362
    value 'SOMALI', '(363) Somali', value: 363
    value 'SONINKE', '(364) Soninke', value: 364
    value 'SORANI', '(365) Sorani', value: 365
    value 'SOTHERN_SOTHO', '(366) Sothern Sotho', value: 366
    value 'SPANISH', '(367) Spanish', value: 367
    value 'SPANISH_CREOLE', '(368) Spanish Creole', value: 368
    value 'SUDANESE_ARABIC', '(369) Sudanese Arabic', value: 369
    value 'SUGPIAQ_ALUTIIQ', '(370) Sugpiaq / Alutiiq', value: 370
    value 'SUNDA', '(371) Sunda', value: 371
    value 'SUSU', '(372) Susu', value: 372
    value 'SWAHILI', '(373) Swahili', value: 373
    value 'SWATI', '(374) Swati', value: 374
    value 'SWEDISH', '(375) Swedish', value: 375
    value 'SYLHETTI', '(376) Sylhetti', value: 376
    value 'TAGALOG', '(377) Tagalog', value: 377
    value 'TAIWANESE', '(378) Taiwanese', value: 378
    value 'TAJIK', '(379) Tajik', value: 379
    value 'TAMIL', '(380) Tamil', value: 380
    value 'TANACROSS', '(381) Tanacross', value: 381
    value 'TANANA', '(382) Tanana', value: 382
    value 'TELUGU', '(383) Telugu', value: 383
    value 'THAI', '(384) Thai', value: 384
    value 'TIBETAN', '(385) Tibetan', value: 385
    value 'TIGRE', '(386) Tigre', value: 386
    value 'TIGRIGNA', '(387) Tigrigna', value: 387
    value 'TLINGIT', '(388) Tlingit', value: 388
    value 'TOISHANESE', '(389) Toishanese', value: 389
    value 'TONGAN', '(390) Tongan', value: 390
    value 'TOORO', '(391) Tooro', value: 391
    value 'TRIQUE', '(392) Trique', value: 392
    value 'TSIMSHIAN', '(393) Tsimshian', value: 393
    value 'TSONGA', '(394) Tsonga', value: 394
    value 'TSWANA', '(395) Tswana', value: 395
    value 'TURKISH', '(396) Turkish', value: 396
    value 'TURKMEN', '(397) Turkmen', value: 397
    value 'TWI', '(398) Twi', value: 398
    value 'TZOTZIL', '(399) Tzotzil', value: 399
    value 'UKRAINIAN', '(400) Ukrainian', value: 400
    value 'UNANGAM_TUNUU_ALEUTIAN_ALEUT', '(401) Unangam Tunuu / Aleutian Aleut', value: 401
    value 'UPPER_KUSKOKWIM', '(402) Upper Kuskokwim', value: 402
    value 'URDU', '(403) Urdu', value: 403
    value 'UYGHUR', '(404) Uyghur', value: 404
    value 'UZBEK', '(405) Uzbek', value: 405
    value 'VENDA', '(406) Venda', value: 406
    value 'VIETNAMESE', '(407) Vietnamese', value: 407
    value 'VISAYAN', '(408) Visayan', value: 408
    value 'WELSH', '(409) Welsh', value: 409
    value 'WODAABE', '(410) Wodaabe', value: 410
    value 'WOLOF', '(411) Wolof', value: 411
    value 'WUZHOU', '(412) Wuzhou', value: 412
    value 'XAAT_K_L_HAIDA', '(413) Xaat Kíl / Haida', value: 413
    value 'XHOSA', '(414) Xhosa', value: 414
    value 'XIANG', '(415) Xiang', value: 415
    value 'YEMENI_ARABIC', '(416) Yemeni Arabic', value: 416
    value 'YIDDISH', '(417) Yiddish', value: 417
    value 'YORUBA', '(418) Yoruba', value: 418
    value 'YUNNANESE', '(419) Yunnanese', value: 419
    value 'YUPIK', '(420) Yupik', value: 420
    value 'ZAPOTECO', '(421) Zapoteco', value: 421
    value 'ZARMA', '(422) Zarma', value: 422
    value 'ZO', '(423) Zo', value: 423
    value 'ZULU', '(424) Zulu', value: 424
    value 'ZUNI', '(425) Zuni', value: 425
    value 'ZYPHE', '(426) Zyphe', value: 426
    value 'DIFFERENT_PREFERRED_LANGUAGE', '(21) Different preferred language', value: 21
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', '(9) Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
    value 'INVALID', 'Invalid Value', value: -999999
  end
end
