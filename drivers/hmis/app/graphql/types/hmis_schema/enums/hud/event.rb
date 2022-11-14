###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::Event < Types::BaseEnum
    description '4.20.2'
    graphql_name 'Event'
    value REFERRAL_TO_PREVENTION_ASSISTANCE_PROJECT, '(1) Referral to Prevention Assistance project', value: 1
    value PROBLEM_SOLVING_DIVERSION_RAPID_RESOLUTION_INTERVENTION_OR_SERVICE, '(2) Problem Solving/Diversion/Rapid Resolution intervention or service', value: 2
    value REFERRAL_TO_SCHEDULED_COORDINATED_ENTRY_CRISIS_NEEDS_ASSESSMENT, '(3) Referral to scheduled Coordinated Entry Crisis Needs Assessment', value: 3
    value REFERRAL_TO_SCHEDULED_COORDINATED_ENTRY_HOUSING_NEEDS_ASSESSMENT, '(4) Referral to scheduled Coordinated Entry Housing Needs Assessment', value: 4
    value REFERRAL_TO_POST_PLACEMENT_FOLLOW_UP_CASE_MANAGEMENT, '(5) Referral to Post-placement/ follow-up case management', value: 5
    value REFERRAL_TO_STREET_OUTREACH_PROJECT_OR_SERVICES, '(6) Referral to Street Outreach project or services', value: 6
    value REFERRAL_TO_HOUSING_NAVIGATION_PROJECT_OR_SERVICES, '(7) Referral to Housing Navigation project or services', value: 7
    value REFERRAL_TO_NON_CONTINUUM_SERVICES_INELIGIBLE_FOR_CONTINUUM_SERVICES, '(8) Referral to Non-continuum services: Ineligible for continuum services', value: 8
    value REFERRAL_TO_NON_CONTINUUM_SERVICES_NO_AVAILABILITY_IN_CONTINUUM_SERVICES, '(9) Referral to Non-continuum services: No availability in continuum services', value: 9
    value REFERRAL_TO_EMERGENCY_SHELTER_BED_OPENING, '(10) Referral to Emergency Shelter bed opening', value: 10
    value REFERRAL_TO_TRANSITIONAL_HOUSING_BED_UNIT_OPENING, '(11) Referral to Transitional Housing bed/unit opening', value: 11
    value REFERRAL_TO_JOINT_TH_RRH_PROJECT_UNIT_RESOURCE_OPENING, '(12) Referral to Joint TH-RRH project/unit/resource opening', value: 12
    value REFERRAL_TO_RRH_PROJECT_RESOURCE_OPENING, '(13) Referral to RRH project resource opening', value: 13
    value REFERRAL_TO_PSH_PROJECT_RESOURCE_OPENING, '(14) Referral to PSH project resource opening', value: 14
    value REFERRAL_TO_OTHER_PH_PROJECT_UNIT_RESOURCE_OPENING, '(15) Referral to Other PH project/unit/resource opening', value: 15
    value REFERRAL_TO_EMERGENCY_ASSISTANCE_FLEX_FUND_FURNITURE_ASSISTANCE, '(16) Referral to emergency assistance/flex fund/furniture assistance', value: 16
    value REFERRAL_TO_EMERGENCY_HOUSING_VOUCHER_EHV, '(17) Referral to Emergency Housing Voucher (EHV)', value: 17
    value REFERRAL_TO_A_HOUSING_STABILITY_VOUCHER, '(18) Referral to a Housing Stability Voucher', value: 18
  end
end
