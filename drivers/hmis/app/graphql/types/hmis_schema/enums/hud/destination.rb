###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::Destination < Types::BaseEnum
    description '3.12.1'
    graphql_name 'Destination'
    value EMERGENCY_SHELTER_INCLUDING_HOTEL_OR_MOTEL_PAID_FOR_WITH_EMERGENCY_SHELTER_VOUCHER_OR_RHY_FUNDED_HOST_HOME_SHELTER, '(1) Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter ', value: 1
    value TRANSITIONAL_HOUSING_FOR_HOMELESS_PERSONS_INCLUDING_HOMELESS_YOUTH, '(2) Transitional housing for homeless persons (including homeless youth)', value: 2
    value PERMANENT_HOUSING_OTHER_THAN_RRH_FOR_FORMERLY_HOMELESS_PERSONS, '(3) Permanent housing (other than RRH) for formerly homeless persons', value: 3
    value PSYCHIATRIC_HOSPITAL_OR_OTHER_PSYCHIATRIC_FACILITY, '(4) Psychiatric hospital or other psychiatric facility', value: 4
    value SUBSTANCE_ABUSE_TREATMENT_FACILITY_OR_DETOX_CENTER, '(5) Substance abuse treatment facility or detox center', value: 5
    value HOSPITAL_OR_OTHER_RESIDENTIAL_NON_PSYCHIATRIC_MEDICAL_FACILITY, '(6) Hospital or other residential non-psychiatric medical facility', value: 6
    value JAIL_PRISON_OR_JUVENILE_DETENTION_FACILITY, '(7) Jail, prison or juvenile detention facility', value: 7
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value RENTAL_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY, '(10) Rental by client, no ongoing housing subsidy', value: 10
    value OWNED_BY_CLIENT_NO_ONGOING_HOUSING_SUBSIDY, '(11) Owned by client, no ongoing housing subsidy', value: 11
    value STAYING_OR_LIVING_WITH_FAMILY_TEMPORARY_TENURE_E_G_ROOM_APARTMENT_OR_HOUSE, '(12) Staying or living with family, temporary tenure (e.g. room, apartment or house)', value: 12
    value STAYING_OR_LIVING_WITH_FRIENDS_TEMPORARY_TENURE_E_G_ROOM_APARTMENT_OR_HOUSE, '(13) Staying or living with friends, temporary tenure (e.g. room apartment or house)', value: 13
    value HOTEL_OR_MOTEL_PAID_FOR_WITHOUT_EMERGENCY_SHELTER_VOUCHER, '(14) Hotel or motel paid for without emergency shelter voucher', value: 14
    value FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME, '(15) Foster care home or foster care group home', value: 15
    value PLACE_NOT_MEANT_FOR_HABITATION_E_G_A_VEHICLE_AN_ABANDONED_BUILDING_BUS_TRAIN_SUBWAY_STATION_AIRPORT_OR_ANYWHERE_OUTSIDE, '(16) Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)', value: 16
    value OTHER, '(17) Other', value: 17
    value SAFE_HAVEN, '(18) Safe Haven', value: 18
    value RENTAL_BY_CLIENT_WITH_VASH_HOUSING_SUBSIDY, '(19) Rental by client, with VASH housing subsidy', value: 19
    value RENTAL_BY_CLIENT_WITH_OTHER_ONGOING_HOUSING_SUBSIDY, '(20) Rental by client, with other ongoing housing subsidy', value: 20
    value OWNED_BY_CLIENT_WITH_ONGOING_HOUSING_SUBSIDY, '(21) Owned by client, with ongoing housing subsidy', value: 21
    value STAYING_OR_LIVING_WITH_FAMILY_PERMANENT_TENURE, '(22) Staying or living with family, permanent tenure', value: 22
    value STAYING_OR_LIVING_WITH_FRIENDS_PERMANENT_TENURE, '(23) Staying or living with friends, permanent tenure', value: 23
    value DECEASED, '(24) Deceased', value: 24
    value LONG_TERM_CARE_FACILITY_OR_NURSING_HOME, '(25) Long-term care facility or nursing home', value: 25
    value MOVED_FROM_ONE_HOPWA_FUNDED_PROJECT_TO_HOPWA_PH, '(26) Moved from one HOPWA funded project to HOPWA PH', value: 26
    value MOVED_FROM_ONE_HOPWA_FUNDED_PROJECT_TO_HOPWA_TH, '(27) Moved from one HOPWA funded project to HOPWA TH', value: 27
    value RENTAL_BY_CLIENT_WITH_GPD_TIP_HOUSING_SUBSIDY, '(28) Rental by client, with GPD TIP housing subsidy', value: 28
    value RESIDENTIAL_PROJECT_OR_HALFWAY_HOUSE_WITH_NO_HOMELESS_CRITERIA, '(29) Residential project or halfway house with no homeless criteria', value: 29
    value NO_EXIT_INTERVIEW_COMPLETED, '(30) No exit interview completed', value: 30
    value RENTAL_BY_CLIENT_WITH_RRH_OR_EQUIVALENT_SUBSIDY, '(31) Rental by client, with RRH or equivalent subsidy', value: 31
    value HOST_HOME_NON_CRISIS, '(32) Host Home (non-crisis)', value: 32
    value RENTAL_BY_CLIENT_WITH_HCV_VOUCHER_TENANT_OR_PROJECT_BASED, '(33) Rental by client, with HCV voucher (tenant or project based)', value: 33
    value RENTAL_BY_CLIENT_IN_A_PUBLIC_HOUSING_UNIT, '(34) Rental by client in a public housing unit', value: 34
    value STAYING_OR_LIVING_IN_A_FAMILY_MEMBER_S_ROOM_APARTMENT_OR_HOUSE, "(35) Staying or living in a family member's room, apartment or house", value: 35
    value STAYING_OR_LIVING_IN_A_FRIEND_S_ROOM_APARTMENT_OR_HOUSE, "(36) Staying or living in a friend's room, apartment or house", value: 36
    value WORKER_UNABLE_TO_DETERMINE, '(37) Worker unable to determine', value: 37
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
