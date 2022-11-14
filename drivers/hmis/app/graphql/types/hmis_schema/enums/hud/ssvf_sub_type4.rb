###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SSVFSubType4 < Types::BaseEnum
    description 'V2.B'
    graphql_name 'SSVFSubType4'
    value HEALTH_CARE_SERVICES, '(1) Health care services', value: 1
    value DAILY_LIVING_SERVICES, '(2) Daily living services', value: 2
    value PERSONAL_FINANCIAL_PLANNING_SERVICES, '(3) Personal financial planning services', value: 3
    value TRANSPORTATION_SERVICES, '(4) Transportation services', value: 4
    value INCOME_SUPPORT_SERVICES, '(5) Income support services', value: 5
    value FIDUCIARY_AND_REPRESENTATIVE_PAYEE_SERVICES, '(6) Fiduciary and representative payee services', value: 6
    value LEGAL_SERVICES_CHILD_SUPPORT, '(7) Legal services - child support', value: 7
    value LEGAL_SERVICES_EVICTION_PREVENTION, '(8) Legal services - eviction prevention', value: 8
    value LEGAL_SERVICES_OUTSTANDING_FINES_AND_PENALTIES, '(9) Legal services - outstanding fines and penalties', value: 9
    value LEGAL_SERVICES_RESTORE_ACQUIRE_DRIVER_S_LICENSE, "(10) Legal services - restore / acquire driver's license", value: 10
    value LEGAL_SERVICES_OTHER, '(11) Legal services - other', value: 11
    value CHILD_CARE, '(12) Child care', value: 12
    value HOUSING_COUNSELING, '(13) Housing counseling', value: 13
  end
end
