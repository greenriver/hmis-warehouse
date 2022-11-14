###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::PATHReferral < Types::BaseEnum
    description 'P2.2'
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
  end
end
